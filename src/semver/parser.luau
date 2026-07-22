local TableExt = require("@std/tableext")

local Parser = {}

export type UnaryOperator = "=" | ">" | ">=" | "<" | "<="
export type BinaryOperator = "||" | ","

export type Revision = {
	read tag: "revision",
	read revision: string,
}

export type Version = {
	read tag: "version",
	read major: number,
	read minor: number,
	read patch: number,
	read prerelease: { string | number }?,
	read build: { string | number }? -- no matter number is meaningless
}

export type Compare = {
	read tag: "compare",
	read operator: UnaryOperator,
	read version: Version,
}

export type Condition = {
	read tag: "condition",
	read operator: BinaryOperator,
	read lhs: Version | Compare | Condition,
	read rhs: Version | Compare | Condition,
}

export type GithubDependency = {
	read registry: "github",
	read scope: string,
	read name: string,
	read revision: Revision
}

export type WallyDependency = {
	read registry: "wally",
	read scope: string,
	read name: string,
	read version: Compare | Condition | Version
}

export type PesdeDependency = {
	read registry: "pesde",
	read scope: string,
	read name: string,
	read version: Compare | Condition | Version
}

export type Dependency = GithubDependency | WallyDependency | PesdeDependency

function Parser.parseVersion(raw_version: string): Compare | Condition | Version
	local trimmed_version = raw_version:gsub(" ", "")

	local first_union_offset = trimmed_version:find("||")
	local first_seprator_offset = trimmed_version:find(",")

	if first_union_offset then
		return {
			tag = "condition",
			operator = "||",
			lhs = Parser.parseVersion(trimmed_version:sub(1, first_union_offset - 1)),
			rhs = Parser.parseVersion(trimmed_version:sub(first_union_offset + 2, -1)),
		}
	elseif first_seprator_offset then
		return {
			tag = "condition",
			operator = ",",
			lhs = Parser.parseVersion(trimmed_version:sub(1, first_seprator_offset - 1)),
			rhs = Parser.parseVersion(trimmed_version:sub(first_seprator_offset + 1, -1)),
		}
	end

	local operators = {
		">=",
		"<=",
		">",
		"<",
		"=",
	} :: { UnaryOperator } -- what if check startwith <. it finds <=. so ordering like this. i should find better way

	for _, operator in operators do
		if trimmed_version:sub(1, #operator) == operator then
			return {
				tag = "compare",
				operator = operator,
				version = Parser.parseVersion(trimmed_version:sub(#operator + 1)) :: Version,
			}
		end
	end

	
	local version_str = trimmed_version
	local version_core, build_str = version_str:match("^([^+]+)%+(.+)$")
	if not version_core then
		build_str = nil
	end
	version_str = version_core or version_str

	local version_part, prerelease_str = version_str:match("^([^%-]+)%-(.+)$")
	if not version_part then
		prerelease_str = nil
	end
	version_str = version_part or version_str

	local major_str, minor_str, patch_str = version_str:match("^(%d+)%.(%d+)%.(%d+)$")
	local major, minor, patch = tonumber(major_str), tonumber(minor_str), tonumber(patch_str)
	local prerelease = if prerelease_str then TableExt.map(prerelease_str:split("."), function(identifier: string)
		return tonumber(identifier) or identifier
	end) else nil
	local build = if build_str then TableExt.map(build_str:split("."), function(identifier: string)
		return tonumber(identifier) or identifier
	end) else nil

	assert(major and minor and patch, `Failed to normalize raw version, expected start with "1.0.0" like but got "{trimmed_version}"`)

	return {
		tag = "version",
		major = major,
		minor = minor,
		patch = patch,
		prerelease = prerelease,
		build = build
	}
end

function Parser.parse(raw_dependency: string): Dependency
	local registry, package = unpack(raw_dependency:split("#"))
	local scope, envelope = unpack(package:split("/"))
	local name, version = unpack(envelope:split("@"))

	if registry == "wally" then
		return {
			registry = "wally",
			scope = scope,
			name = name,
			version = Parser.parseVersion(version),
		}
	elseif registry == "pesde" then
		return {
			registry = "pesde",
			scope = scope,
			name = name,
			version = Parser.parseVersion(version)
		}
	elseif registry == "github" then
		return {
			registry = "github",
			scope = scope,
			name = name,
			revision = {
				tag = "revision",
				revision = version,
			},
		}
	end

	error(`Failed to find registry. expected "github" | "wally" | "pesde" but got "{registry}"`)
end

return Parser