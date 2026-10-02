-- visbad.lua файл.lua — примеры живых состояний, которые visibleLoss помечает видимыми (для отладки разметки).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local agg = {}
for i = 1, G.n do
  if G.flag[i] ~= 2 and good[i] == 1 then
    local st = R.decode(lvl, G.keys[i])
    if def.visibleLoss(lvl, st) then
      local t = {}
      for q, p in ipairs(lvl.pieces) do if p.movable then local x, y = R.xy(lvl, st.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag, x, y, st.fixed[q] and "F" or "") end end
      local k = table.concat(t, " ")
      agg[k] = (agg[k] or 0) + 1
    end
  end
end
for k, v in pairs(agg) do print(v, k) end
SV.freeGraph(G); require("ffi").C.free(good)
