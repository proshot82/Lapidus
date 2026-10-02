-- build/l6j/census2.lua файл.lua [N] — конфигурации деталей по общей линейке tools/vislib.lua (мерка новичка):
-- живых / скрытых / видимых состояний, и «двери» (рёбра живое→скрытое) по конфигурации-назначению.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local VL = V.compute(lvl, G, def, good)
local function cfg(st)
  local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then
    if st.pos[q] == 0 then t[#t+1] = (p.tag or p.what) .. "=смыт" else
      local x, y = R.xy(lvl, st.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag or p.what, x, y, st.fixed[q] and "F" or "") end end end
  return table.concat(t, " ")
end
local agg, keyOf = {}, {}
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local st = R.decode(lvl, G.keys[i])
    local k = cfg(st); keyOf[i] = k
    local a = agg[k] or { 0, 0, 0, 0 }; agg[k] = a
    if good[i] == 1 then a[1] = a[1] + 1 elseif VL.newbie[i] then a[3] = a[3] + 1 else a[2] = a[2] + 1 end
  end
end
-- двери
for i = 1, G.n do
  if good[i] == 1 then
    for e = G.eStart.p[i - 1], G.eStart.p[i] - 1 do
      local j = G.edges.p[e]
      if G.flag[j] ~= 2 and good[j] ~= 1 and not VL.newbie[j] then agg[keyOf[j]][4] = agg[keyOf[j]][4] + 1 end
    end
  end
end
local list = {}
for k, a in pairs(agg) do if a[1] + a[2] > 0 then list[#list+1] = { k, a } end end
table.sort(list, function(a, b) return a[2][1] + a[2][2] > b[2][1] + b[2][2] end)
print("конфигурация деталей                          живых  скрытых  видимых  дверей")
for i = 1, math.min(tonumber(arg[2] or 30), #list) do local a = list[i][2]; print(string.format("%-44s %6d %8d %8d %7d", list[i][1], a[1], a[2], a[3], a[4])) end
