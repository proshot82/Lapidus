-- build/l4d/why.lua файл.lua [N] — из чего состоят видимые и скрытые тупики по общей линейке (tools/vislib.lua):
-- причины пометки (смыто / замёрзла-карман / правило уровня) и сводка по конфигурациям деталей. Решений не печатает.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local VL = V.compute(lvl, G, def, good)
print(string.format("причины пометки новичка: смыто %d, замёрзла/карман %d, правило уровня %d (omni-only %d)", VL.counts.washed, VL.counts.frozen, VL.counts.levelRule, VL.counts.goal))
-- та же линейка без правил уровня — сколько помечает граф сам
local def2 = setmetatable({ visibleLoss = nil }, { __index = def })
local VL2 = V.compute(lvl, G, def2, good)
local agg = {}
local function cfg(st)
  local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then
    if st.pos[q] == 0 then t[#t+1] = (p.tag or p.what) .. "=смыт" else
      local x, y = R.xy(lvl, st.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag or p.what, x, y, st.fixed[q] and "F" or "") end end end
  return table.concat(t, " ")
end
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local k = cfg(VL.states[i])
    local a = agg[k] or { 0, 0, 0, 0 }; agg[k] = a
    if good[i] == 1 then a[1] = a[1] + 1
    elseif not VL.newbie[i] then a[2] = a[2] + 1
    elseif VL2.newbie[i] then a[3] = a[3] + 1
      local why = {}
      for _, q in ipairs(VL.needed) do
        local st = VL.states[i]
        if not st.fixed[q] and st.pos[q] ~= VL.win.pos[q] and not VL.canMove[q][i] then why[#why+1] = (lvl.pieces[q].tag or q) .. ":замёрзла" end
        if VL.sealedBy[q][i] then why[#why+1] = (lvl.pieces[q].tag or q) .. ":карман" end
      end
      a.why = a.why or {}; local w = table.concat(why, ","); a.why[w] = (a.why[w] or 0) + 1
    else a[4] = a[4] + 1 end
  end
end
local list = {}
for k, a in pairs(agg) do list[#list+1] = { k, a } end
table.sort(list, function(a, b) return a[2][1]+a[2][2]+a[2][3]+a[2][4] > b[2][1]+b[2][2]+b[2][3]+b[2][4] end)
print("конфигурация деталей                      живых  скрытых  видимых(граф) видимых(уровень)")
for i = 1, math.min(tonumber(arg[2] or 30), #list) do local a = list[i][2]; local w = {}; for k, v in pairs(a.why or {}) do w[#w+1] = k .. "=" .. v end
  print(string.format("%-40s %6d %8d %8d %8d  %s", list[i][1], a[1], a[2], a[3], a[4], table.concat(w, " "))) end
SV.freeGraph(G); require("ffi").C.free(good)
