local CLIBuilder = require("@pkgs/cli_builder")

local Resolution = require("@src/resolution")
local Solver = require("@src/semver/solver")
local Parser = require("@src/semver/parser")

local Constants = require("@src/constants")

local solved = Solver.solve(Parser.parse("wally#jsdotlua/react@17.2.1"))

Resolution.resolve({ react = "wally#jsdotlua/react@17.2.1" })

--Resolution.resolve("", { ["startup"] = "wally#jsdotlua/react@17.2.1" })

--[[	
CLIBuilder.cli
	.new()
	:setName(Constants.NAME)
	:setVersion(Constants.VERSION)
	:setDescription("A flexible luau package manager.")
	:setGitRepository("https://github.com/sbi-n/lutriever")
	:addCommand(CLIBuilder.command
		.new()
		:setName("install")
		:setDescription("Install dependencies that defined manifest.")
		:setCallback(function(options)
			Install.install()
		end)
		:build())
	:addCommand(CLIBuilder.command
		.new()
		:setName("initialize")
		:setDescription("Create default lutriever manifest.")
		:setCallback(function(options)
			Initialize.initialize()
		end)
		:build())
	:run({ select(2, ...) })
]]