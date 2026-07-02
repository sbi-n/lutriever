local Path = require("@std/path")
local Fs = require("@std/fs")

local Toml = require("@libs/toml")
local Writer = require("@libs/writer")

local Constants = require("@src/constants")
local Types = require("@src/types")

local function initialize()
	--[[
	local default_manifest: Types.Manifest = {
		dependencies = {
		},
	}]]

	if not Fs.exists(Constants.MANIFEST_NAME) then
		Fs.writeStringToFile(Path.join(Constants.MANIFEST_NAME), "[dependencies]")
	end
end

return {
	initialize = initialize,
}
