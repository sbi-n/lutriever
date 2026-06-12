local Fs = require("@std/fs")
local Path = require("@std/path")
local Net = require("@std/net")
local Json = require("@std/json")
local Luau = require("@std/luau")
local TableExt = require("@std/tableext")

local Unzip = require("@packages/unzip")

local Toml = require("@libs/toml")
local Types = require("@src/types")
local Constants = require("@src/constants")

local function install()
	assert(Fs.exists(Constants.MANIFEST_NAME), `Project doesn't exists manifest "{Constants.MANIFEST_NAME}"`)

	local manifest: Types.Manifest = Toml.deserialize(Fs.readFileToString(Constants.MANIFEST_NAME)) :: any

	local dot_lutriever_path = Path.join(Constants.PACKAGES_NAME, Constants.DOT_LUTRIEVER)
	if not Fs.exists(dot_lutriever_path) then
		Fs.createDirectory(dot_lutriever_path, { makeParents = true })
	end

	for alias, dependency in manifest.dependencies do
		local scope, envelope = unpack(dependency:split("/"))
		local name, version = unpack(envelope:split("@"))

		local metadata = Net.request(Constants.WALLY_BASE_URL .. `/v1/package-metadata/{scope}/{name}`)

		local contents = Net.request(Constants.WALLY_BASE_URL .. `/v1/package-contents/{scope}/{name}/{version}`, {
			headers = {
				["wally-version"] = Constants.WALLY_VERSION,
			},
		})

		if metadata.ok and contents.ok then
			local package_name = dependency:gsub("/", "_")
			local package_path = Path.join(Constants.PACKAGES_NAME, Constants.DOT_LUTRIEVER, package_name)
			local alias_path = Path.join(package_path, alias)

			if not Fs.exists(package_path) then
				Fs.createDirectory(package_path)

				if not Fs.exists(alias_path) then
					Fs.createDirectory(alias_path)
				end
			end

			local reader = Unzip.load(buffer.fromstring(contents.body))
			reader:walk(function(entry: Unzip.ZipEntry, depth: number) 
				local dest_path = Path.join(alias_path, entry:sanitizePath())
				
				if entry.isDirectory then
					Fs.createDirectory(dest_path, { makeParents = true })
				else
					Fs.writeStringToFile(dest_path, reader:extract(entry, { type = "text" }))
				end
			end)

			local package_types = Luau.typeofModule(alias)

			Fs.writeStringToFile(
				Path.join(Constants.PACKAGES_NAME, alias .. ".luau"),
				[[
        print("앙 기모띠")
        ]]
			)
		end
	end
end

return {
	install = install,
}
