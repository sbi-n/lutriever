local Path = require("@std/path")
local Fs = require("@std/fs")

local Toml = require("@libs/toml")
local Writer = require("@libs/writer")

local Constants = require("@src/constants")
local Types = require("@src/types")

local function initialize()
	local default_manifest: Types.Manifest = {
		packages = {
			name = "",
			authors = {},
			version = "0.1.0",
		},

		dependencies = {},
	}

	if not Fs.exists(Constants.MANIFEST_NAME) then
	end
end

return {
	initialize = initialize,
}
