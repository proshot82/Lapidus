-- trap.lua файл.lua "tag=x,y tag=x,y ..." ["lap=x,y;x,y;...;H"] — решаем ли уровень из «ловушечного» старта
-- (детали переставлены; закреплённые встанут на место при начальном устаканивании). Печатает только
-- решаемость, число состояний и длину решения — без ходов. Кадры — через build/l6b/check.lua вручную.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
def.visibleLoss = nil
def.ablations = nil
for tok in (arg[2] or ""):gmatch("%S+") do
  local tag, x, y = tok:match("^(%w+)=(%d+),(%d+)$")
  for _, o in ipairs(def.objects) do if o.tag == tag then o.at = { tonumber(x), tonumber(y) } end end
end
if arg[3] then
  local cells = {}
  for x, y in arg[3]:gmatch("(%d+),(%d+)") do cells[#cells + 1] = { tonumber(x), tonumber(y) } end
  for _, o in ipairs(def.objects) do if o.kind == "lapidus" then o.cells = cells; o.head = arg[3]:match(";H$") and #cells or 1 end end
end
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
if not G then print("CAP") return end
print(string.format("%s: %s (состояний %d%s)", arg[2] or "", G.firstWin and "РЕШАЕМ" or "нерешаем", G.n,
  G.firstWin and (", ходов " .. G.depth[G.firstWin]) or ""))
SV.freeGraph(G)
