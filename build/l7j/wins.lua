-- build/l7j/wins.lua файл.lua — все выигрышные конфигурации деталей (положения) и минимальная глубина каждой
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local c = {}
for i = 1, G.n do if G.flag[i] == 1 then
  local st = R.decode(lvl, G.keys[i]); local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then
    if st.pos[q] == 0 then t[#t+1] = p.tag .. "смыт" else local x, y = R.xy(lvl, st.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag, x, y, st.fixed[q] and "F" or "") end end end
  local k = table.concat(t, " ")
  if not c[k] or G.depth[i] < c[k] then c[k] = G.depth[i] end
end end
for k, d in pairs(c) do print(k, "глубина", d) end
