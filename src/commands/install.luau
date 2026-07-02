local Fs = require("@std/fs")
local Path = require("@std/path")
local Net = require("@std/net")
local Json = require("@std/json")
local Luau = require("@std/luau")
local TableExt = require("@std/tableext")
local Process = require("@std/process")

local Unzip = require("@packages/unzip")

local Toml = require("@libs/toml")
local Writer = require("@libs/writer")
local Types = require("@src/types")
local Constants = require("@src/constants")

local function install_folder(path: Path.Pathlike, context: buffer)
	local reader = Unzip.load(context)
	reader:walk(function(entry: Unzip.ZipEntry, depth: number)
		local dest_path = Path.join(path, entry:sanitizePath())

		if entry.isDirectory then
			Fs.createDirectory(dest_path, { makeParents = true })
		else
			Fs.writeStringToFile(dest_path, reader:extract(entry, { type = "text" }))
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

		if registry == "wally" then
			local metadata = Net.request(Constants.WALLY_BASE_URL .. `/v1/package-metadata/{scope}/{name}`)
			local contents = Net.request(Constants.WALLY_BASE_URL .. `/v1/package-contents/{scope}/{name}/{version}`, {
				headers = {
					["wally-version"] = Constants.WALLY_VERSION,
				},
			})

			if contents.ok and metadata.ok then
				install_folder(alias_path, buffer.fromstring(contents.body))
			end
		elseif registry == "github" then
			--git clone --branch v1.1.0 --depth 1 https://github.com/Roblox/cryo packages/.lutriever/shibal
			Process.run({
				"git",
				"clone",
				"--branch",
				version,
				"--depth",
				"1",
				string.format("https://github.com/%s/%s", scope, name),
				string.format(Path.format(alias_path), "\\", "/")

			})
			--[[
			local contents = Net.request(Constants.GITHUB_BASE_URL .. `/{scope}/{name}/archive/refs/tags/{version}.zip`)

			if contents.ok then
				install_folder(alias_path, buffer.fromstring(contents.body))
			end]]
		end

		--local package_types = Luau.typeofModule(alias)

		local package_extern = Writer.new()

		package_extern:append_line(`local module = require("./{Constants.DOT_LUTRIEVER}/{package_name}/{alias}")`)
		package_extern:append("\n")

		package_extern:append("\n")
		package_extern:append_line("return module")

		Fs.writeStringToFile(Path.join(Constants.PACKAGES_NAME, alias .. ".luau"), package_extern:finalize())
	end
end

return {
	install = install,
}
