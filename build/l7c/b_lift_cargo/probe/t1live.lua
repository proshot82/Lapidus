-- живые состояния ловушки «тройник поднят раньше заглушки» (конфигурации, без путей) и их расстояние до победы
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local k = {}
for q, p in ipairs(lvl.pieces) do if p.tag then k[p.tag] = q end end
for i = 1, G.n do
  if G.flag[i] == 0 and good[i] == 1 then
    local st = R.decode(lvl, G.keys[i])
    local tx, ty = R.xy(lvl, st.pos[k.tee])
    local px = R.xy(lvl, st.pos[k.plug])
    if tx == 6 and ty < 5 and px ~= 6 then
      local t = {}
      for q, p in ipairs(lvl.pieces) do if p.movable then local x, y = R.xy(lvl, st.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag, x, y, st.fixed[q] and "F" or "") end end
      local b = {}
      for _, c in ipairs(st.body) do local x, y = R.xy(lvl, c); b[#b+1] = x .. "," .. y end
      print("глубина " .. G.depth[i] .. ": " .. table.concat(t, " ") .. " | тело (ноги→голова) " .. table.concat(b, " "))
    end
  end
end
SV.freeGraph(G)
