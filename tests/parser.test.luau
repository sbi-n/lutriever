local Test = require("@std/test")

local Parser = require("@src/semver/parser")

Test.suite("Parser", function(suite)
	suite:case("ParseVersionSimple", function(assert)
		local parsed = Parser.parseVersion("1.0.0") :: Parser.Version

		assert.eq(parsed.tag, "version")
		assert.eq(parsed.major, 1)
		assert.eq(parsed.minor, 0)
		assert.eq(parsed.patch, 0)
	end)

	suite:case("ParseVersionCompare", function(assert)
		local eqParsed = Parser.parseVersion("=1.0.0") :: Parser.Compare

		assert.eq(eqParsed.tag, "compare")
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
