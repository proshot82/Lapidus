-- wins.lua файл.lua — выигрышные конфигурации деталей и мин. глубина (для себя).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local agg = {}
for i = 1, G.n do
  if G.flag[i] == 1 then
    local st = R.decode(lvl, G.keys[i])
    local t = {}
    for q, p in ipairs(lvl.pieces) do if p.movable then
      local x, y = R.xy(lvl, st.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag or p.what, x, y, st.fixed[q] and "F" or "") end end
    local k = table.concat(t, " ")
    agg[k] = math.min(agg[k] or 1e9, G.depth[i])
  end
end
for k, d in pairs(agg) do print(k, d) end
