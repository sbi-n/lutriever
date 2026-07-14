local Test = require("@std/test")

local Parser = require("@src/semver/parser")

Test.suite("Parser", function(suite)
    suite:case("ParseVersionSimple", function(assert)
        local result = Parser.parseVersion("1.0.0") :: Parser.Version

        assert.eq(result.tag, "version")
        assert.eq(result.major, 1)
        assert.eq(result.minor, 0)
        assert.eq(result.patch, 0)
    end)

    suite:case("ParseVersionCompare", function(assert)
        local eqResult = Parser.parseVersion("=1.0.0") :: Parser.Compare

        assert.eq(eqResult.tag, "compare")
        assert.eq(eqResult.version.major, 1)
        assert.eq(eqResult.version.minor, 0)
        assert.eq(eqResult.version.patch, 0)
    end)
end)