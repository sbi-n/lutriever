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

local function compareNumber(operator: Parser.Operator, lhs: number, rhs: number): boolean
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

local function compareVersion(operator: Parser.Operator, lhs: Parser.Version, rhs: Parser.Version): boolean
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

local function isSatisfied(
	version: Parser.Version,
	requirement: Parser.Version | Parser.Compare | Parser.Condition
): boolean
	if requirement.tag == "compare" then
		return compareVersion(requirement.operator, version, requirement.version)
	elseif requirement.tag == "condition" then
		return isSatisfied(version, requirement.lhs) and isSatisfied(version, requirement.rhs)
	elseif requirement.tag == "version" then
		return version.major == requirement.major
			and version.minor == requirement.minor
			and version.patch == requirement.patch
	end

	error(`Failed to evaluate requirement is satisfied "{requirement.tag}"`)
end

-- 이게 무엇을 반환해주어야하는가. 디펜던시즈?
function Solver.solve(dependency: Parser.Dependency): { Parser.Dependency }
	if dependency.registry == "wally" then
		local wally_metadata_raw =
			Net.request(`{Constants.WALLY_API_URL}/v1/package-metadata/{dependency.scope}/{dependency.name}`)

		assert(wally_metadata_raw.ok, `Failed to fetch wally metadata "{dependency.scope}/{dependency.name}"`)

		local wally_metadata = Json.deserialize(wally_metadata_raw.body) :: WallyMetadata
		local wally_version = TableExt.find(wally_metadata.versions :: any, function(wally_version)
			return isSatisfied(Parser.parseVersion(wally_version.package.version) :: Parser.Version, dependency.version)
		end) :: WallyVersion

		local dependencies = {} :: { Parser.Dependency }
		for _, wally_dependency in wally_version.dependencies do
            if typeof(wally_dependency) ~= "string" then
                continue
            end

			local scope, envelope = unpack(wally_dependency:split("/"))
			local name, version = unpack(envelope:split("@"))

			table.insert(dependencies :: any, {
				registry = "wally",
				scope = scope,
				name = name,
				version = Parser.parseVersion(version),
			})
		end

		return dependencies
	elseif dependency.registry == "github" then
	end

    error(`Failed to solve dependencies in "{dependency.registry}" registry`)
end

return Solver
