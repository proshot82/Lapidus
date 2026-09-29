-- build/l7v_g/marks.lua файл.lua — доля скрытых при разных трактовках правила «деталь лежит там, где её нечем поднять».
-- B: любая подвижная деталь на нижнем полу (строка 7) — видимо проиграно;
-- C: любая подвижная деталь в нижней комнате левее столба (x ≤ 8, строки 5–7) — видимо (сильнее, почти знаток).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local path = arg[1]
local function rule(pred)
  return function(lvl, st)
    for q, p in ipairs(lvl.pieces) do if p.movable and st.pos[q] ~= 0 and not st.fixed[q] then
      local x, y = R.xy(lvl, st.pos[q]); if pred(x, y) then return true end end end
    return false
  end
end
local variants = {
  { "A: линейка (новичок, карман 4)", nil },
  { "B: + деталь на нижнем полу видна", rule(function(x, y) return y == 7 end) },
  { "C: + деталь в нижней комнате левее столба", rule(function(x, y) return y >= 5 and x <= 8 end) },
}
local def0 = dofile(path)
local lvl = R.compile(def0)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
for _, P in ipairs({ 4, 5, 6, 8 }) do
  for _, v in ipairs(variants) do
    local def = dofile(path); def.visibleLoss = v[2]
    V.POCKET = P
    local VL = V.compute(lvl, G, def, good)
    local m = V.measure(G, good, VL.newbie)
    local e = V.measure(G, good, VL.expert)
    print(string.format("карман %d | %-44s | скрытых %6d (%.1f %%) обез %.3f глуб %d [%s] | знаток %.1f %% глуб %d [%s] | правило %d",
      P, v[1], m.hid, m.hiddenPct, m.smart, m.maxDeep, m.deepList, e.hiddenPct, e.maxDeep, e.deepList, VL.counts.levelRule))
  end
end
SV.freeGraph(G); require("ffi").C.free(good)
