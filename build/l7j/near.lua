-- build/l7j/near.lua файл.lua — для каждого шага кратчайшего пути: сколько ходов до ближайшего скрытого тупика и какой он
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
local function cfg(i)
  local st = R.decode(lvl, G.keys[i]); local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then local x, y = R.xy(lvl, st.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag, x, y, st.fixed[q] and "F" or "") end end
  return table.concat(t, " ")
end
local ES, E = G.eStart.p, G.edges.p
for k, s in ipairs(m.path) do
  local d, q, h, found = { [s] = 0 }, { s }, 1, nil
  while h <= #q and not found do
    local u = q[h]; h = h + 1
    for e = ES[u - 1], ES[u] - 1 do
      local v = E[e]
      if d[v] == nil then d[v] = d[u] + 1
        if m.hidden[v] then found = v break end
        if good[v] == 1 and d[v] < 6 then q[#q + 1] = v end
      end
    end
  end
  print(string.format("шаг %d: %s", k - 1, found and string.format("скрытое через %d: %s", d[found], cfg(found)) or "—"))
end
