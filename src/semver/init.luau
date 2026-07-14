local Parser = require("@self/parser")
local Solver = require("@self/solver")


return {
    parse = Parser.parse,
    parseVersion = Parser.parseVersion,

    solve = Solver.solve,
}