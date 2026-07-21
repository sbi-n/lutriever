local Test = require("@std/test")

local Parser = require("@src/semver/parser")

Test.suite("Parser", function(suite)
	suite:case("ParseVersionSimple", function(assert)
		local parsed = Parser.parseVersion("1.2.3") :: Parser.Version

		assert.eq(parsed.prerelease, nil)
		assert.eq(parsed.build, nil)

		assert.eq(parsed.tag, "version")
		assert.eq(parsed.major, 1)
		assert.eq(parsed.minor, 2)
		assert.eq(parsed.patch, 3)
	end)

	suite:case("ParseVersionPreRelease", function(assert)
		local parsed = Parser.parseVersion("1.2.3-rc.1") :: Parser.Version

		assert.neq(parsed.prerelease, nil)
		assert.eq(parsed.build, nil)

		assert.eq(parsed.prerelease[1], "rc")
		assert.eq(parsed.prerelease[2], 1)
		assert.eq(parsed.prerelease[3], nil)
	end)

	suite:case("ParseVersionBuild", function(assert)
		local parsed = Parser.parseVersion("1.2.3+a.b.c")

		assert.eq(parsed.prerelease, nil)
		assert.neq(parsed.build, nil)

		assert.eq(parsed.build[1], "a")
		assert.eq(parsed.build[2], "b")
		assert.eq(parsed.build[3], "c")
		assert.eq(parsed.build[4], nil)
	end)

	suite:case("ParsedVersionNumericBuild", function(assert)
		local parsed = Parser.parseVersion("1.0.0+1.2.3")

		assert.eq(parsed.prerelease, nil)
		assert.neq(parsed.build, nil)

		assert.eq(parsed.build[1], 1)
		assert.eq(parsed.build[2], 2)
		assert.eq(parsed.build[3], 3)
		assert.eq(parsed.build[4], nil)
	end)

	suite:case("ParsedVersionPreReleaseAndBuild", function(assert)
		local parsed = Parser.parseVersion("1.0.0-beta.1+breakingchange")

		assert.neq(parsed.prerelease, nil)
		assert.neq(parsed.build, nil)

		assert.eq(parsed.prerelease[1], "beta")
		assert.eq(parsed.prerelease[2], 1)
		assert.eq(parsed.prerelease[3], nil)

		assert.eq(parsed.build[1], "breakingchange")
		assert.eq(parsed.build[2], nil)
	end)

	suite:case("ParseVersionCompare", function(assert)
		local eqParsed = Parser.parseVersion("=1.0.0") :: Parser.Compare

		assert.eq(eqParsed.tag, "compare")
		assert.eq(eqParsed.operator, "=")
		assert.eq(eqParsed.version.major, 1)
		assert.eq(eqParsed.version.minor, 0)
		assert.eq(eqParsed.version.patch, 0)
	end)

	suite:case("ParseVersionCondition", function(assert)
		local conditionParsed = Parser.parseVersion(">=1.0.0, <2.0.0") :: Parser.Condition
		local lhsCompare, rhsCompare = conditionParsed.lhs :: Parser.Compare, conditionParsed.rhs :: Parser.Compare

		assert.eq(conditionParsed.tag, "condition")
		assert.eq(lhsCompare.tag, "compare")
		assert.eq(rhsCompare.tag, "compare")

        assert.eq(lhsCompare.version.major, 1)
        assert.eq(rhsCompare.version.major, 2)
	end)
end)
