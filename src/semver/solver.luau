local Net = require("@std/net")
local Json = require("@std/json")
local TableExt = require("@std/tableext")

local Constants = require("../constants")
local Parser = require("./parser")

local Solver = {}

export type WallyDependencies = {
	[string]: string,
}

export type WallyVersion = {
	dependencies: WallyDependencies,
	["dev-dependencies"]: WallyDependencies,
	package: {
		version: string,
		name: string,
	},
}

export type WallyMetadata = {
	versions: { WallyVersion },
}

local function compareNumber(operator: Parser.UnaryOperator, lhs: number, rhs: number): boolean
	if operator == ">" then
		return lhs > rhs
	elseif operator == ">=" then
		return lhs >= rhs
	elseif operator == "<" then
		return lhs < rhs
	elseif operator == "<=" then
		return lhs <= rhs
	end

	error(`Failed to find operator in compare "{operator}"`)
end

local function compareVersion(operator: Parser.UnaryOperator, lhs: Parser.Version, rhs: Parser.Version): boolean
	if operator == "=" then
		return lhs.major == rhs.major and lhs.minor == rhs.minor and lhs.patch == rhs.patch
	end

	if lhs.major ~= rhs.major then
		return compareNumber(operator, lhs.major, rhs.major)
	end

	if lhs.minor ~= rhs.minor then
		return compareNumber(operator, lhs.minor, rhs.minor)
	end

	return compareNumber(operator, lhs.patch, rhs.patch)
end

function Solver.eq(lhs: Parser.Version, rhs: Parser.Version)
	return compareVersion("=", lhs, rhs)
end

function Solver.gt(lhs: Parser.Version, rhs: Parser.Version)
	return compareVersion(">", lhs, rhs)
end

function Solver.ge(lhs: Parser.Version, rhs: Parser.Version)
	return compareVersion(">=", lhs, rhs)
end

function Solver.lt(lhs: Parser.Version, rhs: Parser.Version)
	return compareVersion("<", lhs, rhs)
end

function Solver.le(lhs: Parser.Version, rhs: Parser.Version)
	return compareVersion("<=", lhs, rhs)
end

function Solver.satisfies(
	version: Parser.Version,
	requirement: Parser.Version | Parser.Compare | Parser.Condition
): boolean
	if requirement.tag == "compare" then
		return compareVersion(requirement.operator, version, requirement.version)
	elseif requirement.tag == "condition" then
		return Solver.satisfies(version, requirement.lhs) and Solver.satisfies(version, requirement.rhs)
	elseif requirement.tag == "version" then
		return compareVersion("=", version, requirement)
	end

	error(`Failed to find tag of requirement "{requirement.tag}"`)
end

return Solver
