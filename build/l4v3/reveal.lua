-- build/l4v3/reveal.lua — t16: от двери EF (угольник ушёл в спуск) сколько ходов до естественных проверок плана
-- «поднять угольник обратно»: угольник снова наверху спуска (5,4)/(5,3); «довести по полу к машинке»: угольник в (6,5)/(6,6).
package.path = "./?.lua;" .. package.path
local L = dofile("build/l4v3/lib.lua")
local A = L.load("build/l4e/t16.lua")
local cls = L.classes(A)
local H = L.hiddenOf(A, A.VL.newbie)
local G, sts = A.G, A.sts
local ES, E = G.eStart.p, G.edges.p
local e = A.Q.elb
local R = A.R
local function at(i, cells) local c = sts[i].pos[e]; if c == 0 then return false end; local x, y = R.xy(A.lvl, c); return cells[x .. "," .. y] end
local function dist(j, cells)
  local d, q, h = { [j] = 0 }, { j }, 1
  while h <= #q do local u = q[h]; h = h + 1
    if at(u, cells) then return d[u], (A.VL.newbie[u] and "видимо" or "скрыто") end
    for ee = ES[u - 1], ES[u] - 1 do local v = E[ee]; if G.flag[v] ~= 2 and d[v] == nil then d[v] = d[u] + 1; q[#q + 1] = v end end end
end
for _, dd in ipairs(L.doors(A, H, false)) do
  local j = dd.to
  local a, av = dist(j, { ["5,4"] = true, ["5,3"] = true })
  local b, bv = dist(j, { ["6,5"] = true, ["6,6"] = true })
  print(string.format("дверь с шага %d: до «угольник снова наверху спуска» %s (%s); до «угольник у машинки внизу» %s (%s); глубина области %d",
    dd.step, tostring(a), tostring(av), tostring(b), tostring(bv), (L.depthFrom(A, H, j))))
end
