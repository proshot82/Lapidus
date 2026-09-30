-- build/l5d/ctl.lua файл.lua — абляции и контроли кандидата: решаем ли вариант, сколько ходов, доля скрытых и
-- умная обезьяна (по общей линейке, карман 4) — чтобы видеть несущность каждой ошибки (запрет — насколько легче).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local function run(name, d, filter)
  local ok, lvl = pcall(R.compile, d)
  if not ok or #R.validate(lvl) > 0 then print(string.format("  %-70s НЕКОРРЕКТЕН", name)) return end
  local G = SV.explore(lvl, 3000000, filter)
  if not G.firstWin then print(string.format("  %-70s нерешаем (состояний %d)", name, G.n)); SV.freeGraph(G) return end
  local good = SV.goodSet(G)
  local VL = V.compute(lvl, G, d, good)
  local m = V.measure(G, good, VL.newbie)
  print(string.format("  %-70s решаем: ходов %d, состояний %d, скрытых %.0f %%, обезьяна %.2f %%", name, m.opt, G.n, m.hiddenPct, m.smart))
  SV.freeGraph(G); require("ffi").C.free(good)
end
run("исходный", def)
print("абляции:")
for _, a in ipairs(def.ablations or {}) do
  local d = SV.deepcopy(def); d.ablations = nil; d.visibleLoss = def.visibleLoss
  SV.applyAblation(d, a)
  run(a.name, d, a.filter)
end
print("контроли:")
for _, a in ipairs(def.controls or {}) do
  local d = SV.deepcopy(def); d.ablations = nil; d.visibleLoss = def.visibleLoss
  SV.applyAblation(d, a)
  run(a.name, d, a.filter)
end
