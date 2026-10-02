-- analyze.lua файл.lua — метрики §7 (solver/solve.lua analyze), без решений.
package.path = "./?.lua;" .. package.path
local SV = require("solver.solve")
local def = dofile(arg[1])
local res = SV.analyze(def, { cap = 3000000 })
print(SV.summary(res))
