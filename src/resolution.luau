local TableExt = require("@std/tableext")

local Sember = require("@src/semver")

local Resolution = {}

-- TODO: 솔브를 어떻게 최적화 하고, 어떻게 값을 줘야하는가. 정확한버전과 하위 디펜던시를 얻으려면
function Resolution.resolve(raw_dependencies: { [string]: string })
end

return Resolution
