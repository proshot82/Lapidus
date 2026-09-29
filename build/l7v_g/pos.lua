-- build/l7v_g/pos.lua файл.lua — по каждой детали и клетке: живых / скрытых / видимых состояний (мерка новичка, карман 4).
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
  local s = R.decode(lvl, G.keys[i])
  for q, p in ipairs(lvl.pieces) do if p.movable then
    local k
    if s.pos[q] == 0 then k = p.tag .. " смыт" else local x, y = R.xy(lvl, s.pos[q]); k = string.format("%s (%d,%d)%s", p.tag, x, y, s.fixed[q] and "F" or "") end
    local a = agg[k] or { 0, 0, 0 }; agg[k] = a
    if good[i] == 1 then a[1] = a[1] + 1 elseif VL.newbie[i] then a[3] = a[3] + 1 else a[2] = a[2] + 1 end
  end end
end end
local l = {} for k, a in pairs(agg) do l[#l+1] = { k, a } end
table.sort(l, function(x, y) return x[1] < y[1] end)
for _, e in ipairs(l) do print(string.format("%-16s жив %5d скр %6d вид %6d", e[1], e[2][1], e[2][2], e[2][3])) end
