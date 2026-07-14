local Parser = {}

export type Operator = "=" | ">" | ">=" | "<" | "<="

export type Revision = {
	read tag: "revision",
	read revision: string,
}

export type Version = {
	read tag: "version",
	read major: number,
	read minor: number,
	read patch: number,
}

export type Compare = {
	read tag: "compare",
	read operator: Operator,
	read version: Version,
}

export type Condition = {
	read tag: "condition",
	read lhs: Version | Compare | Condition,
	read rhs: Version | Compare | Condition,
}

export type Dependency = {
	scope: string,
	name: string,
} & ({
	registry: "github",
	version: Revision,
} | {
	registry: "wally",
	version: Compare | Version | Condition,
})

function Parser.parseVersion(raw_version: string): Compare | Version | Condition
	-- local majorStr, minorStr, patchStr = rawVersion:match("^(%d+)%.(%d+)%.(%d+)$")
	local trimmed_version = raw_version:gsub(" ", "")
	local first_seperator_offset = string.find(trimmed_version, ",")

	if first_seperator_offset then
		return {
			tag = "condition",
			lhs = Parser.parseVersion(trimmed_version:sub(1, first_seperator_offset - 1)),
			rhs = Parser.parseVersion(trimmed_version:sub(first_seperator_offset + 1, -1)),
		}
	end

	local operators = {
		"=",
		">=",
		"<=",
		">",
		"<",
	} :: { Operator } -- what if check startwith <. it finds <=. so ordering like this. i should find better way

	for _, operator in operators do
		if trimmed_version:sub(1, #operator) == operator then
			return {
				tag = "compare",
				operator = operator,
				version = Parser.parseVersion(trimmed_version:sub(#operator + 1)) :: Version,
			}
		end
	end

	local major_str, minor_str, patch_str = raw_version:match("^(%d+)%.(%d+)%.(%d+)$")
	local major, minor, patch = tonumber(major_str), tonumber(minor_str), tonumber(patch_str)

	if not (major and minor and patch) then
		error(`Failed to normalize raw version, expected "1.0.0" like but got "{trimmed_version}"`)
	end

	return {
		tag = "version",
		major = major,
		minor = minor,
		patch = patch,
	}
end

--[[
 startup = "wally#sbi-n/startup@0.2.3"
]]

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
	elseif registry == "github" then
		return {
			registry = "github",
			scope = scope,
			name = name,
			version = {
				tag = "revision",
				revision = version :: any,
			},
		}
	end

	error(`Failed to find registry. expected "github" | "wally" but got "registry"`)
end

return Parser
