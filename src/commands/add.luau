local Fs = require("@std/fs")
local Path = require("@std/path")

local Toml = require("@libs/toml")
local Types = require("@src/types")
local Constants = require("@src/constants")

local function add()
	local manifest: Types.Manifest = Toml.deserialize(Fs.readFileToString(Constants.MANIFEST_NAME)) :: any

    
end

return {
    add = add
}