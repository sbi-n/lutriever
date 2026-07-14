local TableExt = require("@std/tableext")

local Sember = require("@src/semver")

local Resolution = {}

function Resolution.resolve(dependencies: { [string]: string })
	local mapped_dependencies = TableExt.map(dependencies, function(raw_dependency: string)
		return Sember.solve(Sember.parse(raw_dependency))
	end)

    
end

return Resolution
