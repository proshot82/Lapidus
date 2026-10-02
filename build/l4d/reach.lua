-- build/l4d/reach.lua файл.lua — какие конфигурации деталей вообще достижимы (для отладки нерешаемых вариантов).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local agg = {}
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local st = R.decode(lvl, G.keys[i])
    local t = {}
    for q, p in ipairs(lvl.pieces) do if p.movable then local x, y = R.xy(lvl, st.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag, x, y, st.fixed[q] and "F" or "") end end
    local k = table.concat(t, " ")
    agg[k] = (agg[k] or 0) + 1
  end
end
local l = {}
for k, v in pairs(agg) do l[#l+1] = k .. " " .. v end
table.sort(l)
for _, s in ipairs(l) do print(s) end
SV.freeGraph(G)
