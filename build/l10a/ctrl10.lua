-- build/l10a/ctrl10.lua файл.lua — несущность ошибок плана: для каждого контроля (фильтр, снимающий одну ошибку) —
-- решаем ли, за сколько ходов, сколько состояний, доля скрытых по линейке новичка, умная обезьяна. Только метрики.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local function run(name, ab)
  local d2 = SV.deepcopy(def); d2.ablations = nil; d2.controls = nil
  SV.applyAblation(d2, ab)
  local lvl = R.compile(d2)
  local G = SV.explore(lvl, 3000000, ab.filter)
  if not G then print(name .. ": CAP") return end
  if not G.firstWin then print(string.format("%-45s нерешаем | состояний %d", name, G.n)) SV.freeGraph(G) return end
  local good = SV.goodSet(G)
  local VL = V.compute(lvl, G, d2, good)
  local m = V.measure(G, good, VL.newbie)
  print(string.format("%-45s решаем за %d | состояний %d | скрытых %.1f %% | обезьяна %.3f %% | глубина %d у пути [%s]",
    name, m.opt, G.n, m.hiddenPct, m.smart, m.maxDeep, m.deepList))
  SV.freeGraph(G); require("ffi").C.free(good)
end
run("база", {})
for _, ab in ipairs(def.controls or {}) do run("контроль: " .. ab.name, ab) end
for _, ab in ipairs(def.ablations or {}) do if ab.filter then run("абляция: " .. ab.name, ab) end end
