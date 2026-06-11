local Fs = require("@std/fs")
local Path = require("@std/path")
local Net = require("@std/net")
local Json = require("@std/json")

local Toml = require("@libs/toml")
local Types = require("@src/types")
local Constants = require("@src/constants")

local function install()
	assert(Fs.exists(Constants.MANIFEST_NAME), `Project doesn't exists manifest "{Constants.MANIFEST_NAME}"`)

	local manifest: Types.Manifest = Toml.deserialize(Fs.readFileToString(Constants.MANIFEST_NAME)) :: any

	if not Fs.exists(Constants.PACKAGES_NAME) then
		Fs.createDirectory(Constants.PACKAGES_NAME)

		local dot_lutriever_path = Path.join(Constants.PACKAGES_NAME, Constants.DOT_LUTRIEVER)
		if not Fs.exists(dot_lutriever_path) then
			Fs.createDirectory(dot_lutriever_path)
		end
	end

	for alias, dependency in manifest.dependencies do
		local scope, envelope = unpack(dependency:split("/"))
		local name, version = unpack(envelope:split("@"))

		--Fs.createDirectory(Path.join(Constants.PACKAGES_NAME, Constants.DOT_LUTRIEVER, dependency_name))

		local response = Net.request(Constants.WALLY_BASE_URL .. `/v1/package-metadata/{scope}/{name}`)

		if response.ok then
            print(response.body)
            --[[
			for i, v in Json.deserialize(response.body).versions :: any do
				print(i, v)
			end
            ]]
		end
	end

	for alias, dependency in manifest.dependencies do
		Fs.writeStringToFile(
			Path.join(Constants.PACKAGES_NAME, alias .. ".luau"),
			[[
        print("앙 기모띠")
        ]]
		)
	end
end

return {
	install = install,
}
