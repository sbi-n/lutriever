local CLIBuilder = require("@packages/cli_builder")

local Install = require("@commands/install")
local Initialize = require("@commands/initialize")

local Constants = require("@src/constants")

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
