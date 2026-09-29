-- build/l4e/ctrl.lua файл.lua — контроли уровня (поле controls: mutate / filter) должны оставаться РЕШАЕМЫМИ;
-- печатает ходы, скрытых %, глубину, обезьяну. Плюс вынужденные ходы подряд и живые с пометкой видимого. Решений нет.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local VL = V.compute(lvl, G, def, good)
local live, liveMarked = 0, 0
for i = 1, G.n do if G.flag[i] ~= 2 and good[i] == 1 then live = live + 1; if VL.newbie[i] then liveMarked = liveMarked + 1 end end end
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
local run1, maxRun1 = 0, 0
for i = 1, #path - 1 do
  local s, safe = path[i], 0
  for e = G.eStart.p[s - 1], G.eStart.p[s] - 1 do if good[G.edges.p[e]] == 1 then safe = safe + 1 end end
  if safe == 1 then run1 = run1 + 1; if run1 > maxRun1 then maxRun1 = run1 end else run1 = 0 end
end
print(string.format("вынужденных ходов подряд %d (≤3) | живых с пометкой видимого %d (=0)", maxRun1, liveMarked))
SV.freeGraph(G); require("ffi").C.free(good)
for _, c in ipairs(def.controls or {}) do
  local d2 = SV.deepcopy(def); d2.ablations = nil; d2.controls = nil; if c.mutate then c.mutate(d2) end
  local ok, l2 = pcall(R.compile, d2)
  local G2 = ok and #R.validate(l2) == 0 and SV.explore(l2, 3000000, c.filter)
  if G2 and G2.firstWin then
    local g2 = SV.goodSet(G2); local VL2 = V.compute(l2, G2, d2, g2); local M2 = V.measure(G2, g2, VL2.newbie)
    print(string.format("%s: РЕШАЕМ за %d, скрытых %.0f %%, глубина %d, обезьяна %.2f %%", c.name, G2.depth[G2.firstWin], M2.hiddenPct, M2.maxDeep, M2.smart))
    SV.freeGraph(G2); require("ffi").C.free(g2)
  else print(c.name .. ": НЕРЕШАЕМ/невалиден") if G2 then SV.freeGraph(G2) end end
end
