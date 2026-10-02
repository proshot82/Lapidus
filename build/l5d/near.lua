-- build/l5d/near.lua файл.lua — для каждого шага кратчайшего пути: сколько ходов до ближайшего СКРЫТОГО тупика
-- (1 = дверь) и до ближайшего видимого; только метрики, без ходов.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local VL = V.compute(lvl, G, def, good)
local m = V.measure(G, good, VL.newbie)
local ES, E, flag = G.eStart.p, G.edges.p, G.flag
local out = {}
for k = 1, #m.path - 1 do
  local s = m.path[k]
  local d, q, h, dh, dv = { [s] = 0 }, { s }, 1, nil, nil
  while h <= #q and not dh do
    local u = q[h]; h = h + 1
    for e = ES[u-1], ES[u]-1 do local v = E[e]
      if d[v] == nil and flag[v] == 0 then
        d[v] = d[u] + 1
        if m.hidden[v] then dh = d[v] break end
        if VL.newbie[v] and not dv then dv = d[v] end
        if good[v] == 1 and d[v] < 6 then q[#q+1] = v end
      end
    end
  end
  out[#out+1] = string.format("%d:%s", k - 1, dh and tostring(dh) or "-")
end
print("шаг:ходов до скрытого тупика (через живые, до 6) — " .. table.concat(out, " "))
SV.freeGraph(G); require("ffi").C.free(good)
