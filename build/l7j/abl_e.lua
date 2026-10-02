-- build/l7j/abl_e.lua файл.lua — пробные абляции ролей: ступенька на свободной детали / на закреплённой
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local function mk(tag, fixedWanted)
  return function(lvl, st, ns)
    local q; for i, p in ipairs(lvl.pieces) do if p.tag == tag then q = i end end
    local c = ns.pos[q]
    if c == 0 or (ns.fixed[q] ~= fixedWanted) then return true end
    local up = lvl.nb[c][R.UP]
    for _, b in ipairs(ns.body) do if b == up then return false end end
    return true
  end
end
local d = SV.deepcopy(def)
d.ablations = {
  { name = "на свободный угольник не встают", filter = mk("elb", false) },
  { name = "на свободный переходник не встают", filter = mk("ada", false) },
  { name = "на вкрученный переходник не встают", filter = mk("ada", true) },
  { name = "на вкрученный угольник не встают", filter = mk("elb", true) },
}
for _, a in ipairs(SV.ablations(d, { cap = 3000000 })) do print(a.name .. ": " .. (a.solvable == true and "решаем" or "НЕРЕШАЕМ")) end
