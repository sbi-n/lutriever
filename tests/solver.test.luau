local Test = require("@std/test")

local Solver = require("@src/semver/solver")
local Parser = require("@src/semver/parser")

Test.suite("Solver", function(suite)
	suite:case("SolveDependencies", function(assert)
		local parsed = Parser.parse("wally#jsdotlua/react@17.2.1")
		local solved = Solver.solve(parsed)

		assert.neq(solved[1], nil)
	end)
end)
