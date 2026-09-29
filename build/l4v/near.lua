-- build/l4v/near.lua — сколько выигрышных последовательностей длиной opt..opt+3 и сколько состояний лежит
-- на почти-кратчайших путях (d(start,s)+d(s,win) ≤ opt+k). Только числа.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1] or "build/l4d/k29.lua")
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local ES, E = G.eStart.p, G.edges.p
local opt = G.depth[G.firstWin]
-- расстояние до победы (обратный BFS)
local rev = {}
for i = 1, G.n do for e = ES[i-1], ES[i]-1 do local j = E[e]; rev[j] = rev[j] or {}; rev[j][#rev[j]+1] = i end end
local dw, q = {}, {}
for i = 1, G.n do if G.flag[i] == 1 then dw[i] = 0; q[#q+1] = i end end
local h = 1
while h <= #q do local j = q[h]; h = h + 1; for _, i in ipairs(rev[j] or {}) do if dw[i] == nil and G.flag[i] == 0 then dw[i] = dw[j] + 1; q[#q+1] = i end end end
-- число последовательностей
local cur, tot = { [1] = 1 }, {}
for L = 1, opt + 3 do
  local nx = {}
  for i, c in pairs(cur) do
    for e = ES[i-1], ES[i]-1 do
      local j = E[e]
      if G.flag[j] == 1 then tot[L] = (tot[L] or 0) + c
      elseif G.flag[j] == 0 and dw[j] and dw[j] <= opt + 3 - L then nx[j] = (nx[j] or 0) + c end
    end
  end
  cur = nx
end
for k = 0, 3 do
  local nst, byDepth = 0, {}
  for i = 1, G.n do if G.flag[i] ~= 2 and dw[i] and G.depth[i] + dw[i] <= opt + k then nst = nst + 1; byDepth[G.depth[i]] = (byDepth[G.depth[i]] or 0) + 1 end end
  local mw = 0; for _, w in pairs(byDepth) do if w > mw then mw = w end end
  print(string.format("opt+%d: выигрышных последовательностей длины %d: %d; состояний на путях ≤opt+%d: %d (макс. на одном расстоянии от старта %d)",
    k, opt + k, tot[opt + k] or 0, k, nst, mw))
end
-- на скольких шагах кратчайшего пути есть альтернативный ход, дающий решение ≤ opt+2
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
local alt = {}
for k = 1, #path - 1 do
  local s, a = path[k], 0
  for e = ES[s-1], ES[s]-1 do local j = E[e]; if j ~= path[k+1] and G.flag[j] ~= 2 and dw[j] and (k) + dw[j] <= opt + 2 then a = a + 1 end end
  alt[#alt+1] = a
end
print("по шагам пути: альтернатив, укладывающихся в opt+2: " .. table.concat(alt, ""))
