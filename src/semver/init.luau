local Parser = require("@self/parser")
local Solver = require("@self/solver")

export type Dependency = Parser.Dependency
export type Revision = Parser.Revision
export type Compare = Parser.Compare
export type Condition = Parser.Condition
export type Version = Parser.Version

return {
    parse = Parser.parse,
    parseVersion = Parser.parseVersion,

    solve = Solver.solve,
}