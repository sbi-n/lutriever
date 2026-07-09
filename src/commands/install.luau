local Fs = require("@std/fs")
local Path = require("@std/path")
local Net = require("@std/net")
local Json = require("@std/json")
local Syntax = require("@std/syntax")
local Query = require("@std/syntax/query")
local Utils = require("@std/syntax/utils")
local Process = require("@std/process")
local TableExt = require("@std/tableext")

local Unzip = require("@packages/unzip")

local Toml = require("@libs/toml")
local Writer = require("@libs/writer")
local Types = require("@src/types")
local Constants = require("@src/constants")

type ProjectObject = {
	["$path"]: string,
	["$className"]: string,
	[string]: ProjectObject,
}

type ProjectManifest = {
	name: string,
	tree: ProjectObject,
}

local function read_module_context(module_path: Path.Pathlike): string?
	local init_lua_path = Path.join(module_path, "init.lua")
	local init_luau_path = Path.join(module_path, "init.luau")

	assert(Fs.exists(module_path), string.format("%s doesn't exist", Path.format(module_path)))

	if Fs.type(module_path) == "file" then
		return Fs.readFileToString(module_path)
	elseif Fs.exists(init_lua_path) and Fs.type(init_lua_path) == "file" then
		return Fs.readFileToString(init_lua_path)
	elseif Fs.exists(init_luau_path) and Fs.type(init_luau_path) == "file" then
		return Fs.readFileToString(init_luau_path)
	end

	return nil
end

local function install_folder(path: Path.Pathlike, context: buffer)
	local reader = Unzip.load(context)
	reader:walk(function(entry: Unzip.ZipEntry, depth: number)
		local dest_path = Path.join(path, entry:sanitizePath())

		if entry.isDirectory then
			Fs.createDirectory(dest_path, { makeParents = true })
		else
			Fs.writeStringToFile(dest_path, reader:extract(entry, { type = "text" }) :: string) -- force type
		end
	end)

	return reader
end

local function install()
	assert(Fs.exists(Constants.MANIFEST_NAME), `Project doesn't exists manifest "{Constants.MANIFEST_NAME}"`)

	local manifest: Types.Manifest = Toml.deserialize(Fs.readFileToString(Constants.MANIFEST_NAME)) :: any

	local dot_lutriever_path = Path.join(Constants.PACKAGES_NAME, Constants.DOT_LUTRIEVER)
	if not Fs.exists(dot_lutriever_path) then
		Fs.createDirectory(dot_lutriever_path, { makeParents = true })
	end

	for alias, dependency in manifest.dependencies do
		local registry, package = unpack(dependency:split("#"))
		local scope, envelope = unpack(package:split("/"))
		local name, version = unpack(envelope:split("@"))

		local package_name = dependency:gsub("/", "_")
		local package_path = Path.join(Constants.PACKAGES_NAME, Constants.DOT_LUTRIEVER, package_name)
		local alias_path = Path.join(package_path, alias)

		assert(registry and scope and name and version, `failed to parse version of "{alias}"`)

		if not Fs.exists(alias_path) then
			Fs.createDirectory(alias_path, { makeParents = true })
		end

		if false then
			local success, message = pcall(function()
				if registry == "wally" then
					local metadata = Net.request(Constants.WALLY_BASE_URL .. `/v1/package-metadata/{scope}/{name}`)
					local contents =
						Net.request(Constants.WALLY_BASE_URL .. `/v1/package-contents/{scope}/{name}/{version}`, {
							headers = {
								["wally-version"] = Constants.WALLY_VERSION,
							},
						})

					if contents.ok and metadata.ok then
						install_folder(alias_path, buffer.fromstring(contents.body))
					else
						error(
							string.format(
								"Failed to fetch wally dependency, %s\n%s",
								dependency,
								not contents.ok and contents.body
									or not metadata.ok and metadata.body
									or "Error message not given."
							)
						)
					end
				elseif registry == "github" then
					local process_result = Process.run({
						"git",
						"clone",
						"--branch",
						version,
						"--depth",
						"1",
						string.format("https://github.com/%s/%s.git", scope, name),
						string.format(Path.format(alias_path), "\\", "/"),
					})

					if not process_result.ok then
						error(
							string.format(
								"Failed to clone github dependency, %s\n%s",
								dependency,
								process_result.stderr
							)
						)
					end
				end
			end)

			if success then
				print(string.format("Installed %s.", dependency))
			else
				-- what if failed, it hints message is string
				print(string.format("Failed to install dependency:\n\n%s", message :: string)) -- warn
				return
			end
		end

		local package_extern = Writer.new()

		package_extern:append_line(`local module = require("./{Constants.DOT_LUTRIEVER}/{package_name}/{alias}")`)
		package_extern:append("\n")

		local default_project_path = Path.join(alias_path, Constants.DEFAULT_PROJECT_JSON)
		if Fs.exists(default_project_path) then
			local project_context = Json.deserialize(Fs.readFileToString(default_project_path)) :: ProjectManifest
			local project_root_path = project_context and project_context.tree["$path"]

			if project_root_path then
				local entry_path = Path.join(alias_path, project_root_path)
				local entry_context = read_module_context(entry_path)

				if entry_context then
					local entry_cst = Syntax.parse(entry_context)
					Query.findAllFromRoot(entry_cst, Utils.isStatTypeAlias):forEach(function(cstStatTypeAlias: any)
						if cstStatTypeAlias.isExported then
							local name = cstStatTypeAlias.name.text
							local generics = cstStatTypeAlias.generics
							local generic_packs = cstStatTypeAlias.genericPacks

							if generics or generic_packs then
								local extended_generics = {}
								if generics and generic_packs then
									TableExt.extend(extended_generics, generics, generic_packs)
								end

								local flatten_generics = generics and generic_packs and extended_generics
									or generics
									or generic_packs

								local generics_text = `<{table.concat(
									TableExt.map(flatten_generics :: { unknown }, function(generic: any)
										local ellipsis = generic.ellipsis

										return ellipsis and generic.name.text .. ellipsis.text or generic.name.text
									end),
									", "
								)}>`

								package_extern:append_line(
									`export type {name}{generics_text} = module.{name}{generics_text}`
								)
							else
								package_extern:append_line(`export type {name} = module.{name}`)
							end
						end
					end)
				end
			end
		end

		package_extern:append("\n")
		package_extern:append_line("return module")

		Fs.writeStringToFile(Path.join(Constants.PACKAGES_NAME, alias .. ".luau"), package_extern:finalize())
	end
end

return {
	install = install,
}
