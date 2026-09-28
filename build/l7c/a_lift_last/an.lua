-- an.lua файл.lua — сводка SV.analyze (как в run_all, но без записи отчётов) + доп. абляции удаления по тегам.
package.path = "./?.lua;" .. package.path
local SV = require("solver.solve")
local def = SV.loadDef(arg[1])
local res = SV.analyze(def, { cap = 5000000 })
print(SV.summary(res))
for i = 2, #arg do
  local d2 = SV.deepcopy(def); d2.ablations = { { name = "без " .. arg[i], remove = arg[i] } }
  for _, a in ipairs(SV.ablations(d2, { cap = 3000000 })) do print(a.name .. ": " .. tostring(a.solvable)) end
end
