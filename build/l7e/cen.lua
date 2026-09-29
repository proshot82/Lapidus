-- build/l7e/cen.lua файл.lua — перепись скрытых/живых/видимых по конфигурации деталей (разметка — общая линейка).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local VL = V.compute(lvl, G, def, good)
local agg = {}
for i = 1, G.n do if G.flag[i] ~= 2 then
  local st = VL.states[i]
  local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then
    if st.pos[q] == 0 then t[#t+1] = p.tag .. "=смыт" else
    local x, y = R.xy(lvl, st.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag, x, y, st.fixed[q] and "F" or "") end end end
  local k = table.concat(t, " ")
  local a = agg[k] or { 0, 0, 0, 0 }; agg[k] = a
  if good[i] == 1 then a[1] = a[1] + 1 elseif VL.newbie[i] then a[3] = a[3] + 1 else a[2] = a[2] + 1; if VL.expert[i] then a[4]=a[4]+1 end end
end end
local list = {}
for k, a in pairs(agg) do list[#list+1] = { k, a } end
table.sort(list, function(a, b) return a[2][2] > b[2][2] end)
print("конфигурация                      живых  скрытых(из них знаток) видимых")
for i = 1, math.min(tonumber(arg[2] or 40), #list) do local a = list[i][2]; print(string.format("%-32s %6d %8d(%d) %8d", list[i][1], a[1], a[2], a[4], a[3])) end
print("counts", VL.counts.frozen, VL.counts.washed, VL.counts.goal)
