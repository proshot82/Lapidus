-- build/l7j/ctrl.lua файл.lua — контроли уровня (def.controls) должны оставаться РЕШАЕМЫМИ
package.path = "./?.lua;" .. package.path
local SV = require("solver.solve")
local def = dofile(arg[1])
local d = SV.deepcopy(def)
d.ablations = def.controls or {}
for _, a in ipairs(SV.ablations(d, { cap = 3000000 })) do print(a.name .. ": " .. (a.solvable == true and "решаем" or "НЕРЕШАЕМ")) end
