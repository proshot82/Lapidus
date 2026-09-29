-- build/l4v3/ef.lua файл — спорный класс «угольник внизу»: где он бывает, можно ли его поднять, куда уходит (без ходов)
package.path = "./?.lua;" .. package.path
local L = dofile("build/l4v3/lib.lua")
local A = L.load(arg[1])
local G, sts, Q = A.G, A.sts, A.Q
local ES, E = G.eStart.p, G.edges.p
local e = Q.elb
local cellsLow, toGoal, upSpout, toTop = {}, 0, 0, {}
for i = 1, G.n do if G.flag[i] ~= 2 and L.lowFree(A, sts[i], e) then
  local x, y = L.xy(A, sts[i].pos[e]); local k = x .. "," .. y
  cellsLow[k] = (cellsLow[k] or 0) + 1
  for ee = ES[i - 1], ES[i] - 1 do local j = E[ee]; if G.flag[j] ~= 2 then local s2 = sts[j]
    if s2.fixed[e] and s2.pos[e] == A.washIn then toGoal = toGoal + 1 end
    if s2.pos[e] ~= 0 and not s2.fixed[e] then local x2, y2 = L.xy(A, s2.pos[e]); if y2 <= 4 then toTop[x2 .. "," .. y2] = (toTop[x2 .. "," .. y2] or 0) + 1 end end
  end end
end end
local t = {}; for k, v in pairs(cellsLow) do t[#t + 1] = k .. ":" .. v end; table.sort(t)
print("угольник свободен внизу, клетки: " .. table.concat(t, " "))
print("переходов «угольник внизу → прикручен к машинке»: " .. toGoal)
local u = {}; for k, v in pairs(toTop) do u[#u + 1] = k .. ":" .. v end; table.sort(u)
print("переходов «угольник внизу → поднят в y<=4», клетки: " .. (#u > 0 and table.concat(u, " ") or "нет"))
-- из состояний с угольником наверху (y<=4), попавших туда снизу: бывает ли угольник снова правее спуска
local topCells = {}
for i = 1, G.n do if G.flag[i] ~= 2 then local s = sts[i]
  if s.pos[e] ~= 0 and not s.fixed[e] then local x, y = L.xy(A, s.pos[e]); if y <= 4 then
    local k = x .. "," .. y; topCells[k] = topCells[k] or { 0, 0 }; if A.good[i] == 1 then topCells[k][1] = topCells[k][1] + 1 else topCells[k][2] = topCells[k][2] + 1 end end end end end
local v = {}; for k, c in pairs(topCells) do v[#v + 1] = string.format("%s живых %d / мёртвых %d", k, c[1], c[2]) end; table.sort(v)
print("свободный угольник наверху: " .. table.concat(v, "; "))
-- раскладки после «угольник внизу → прикручен к машинке» и почему они мертвы
local agg = {}
for i = 1, G.n do if G.flag[i] ~= 2 and L.lowFree(A, sts[i], e) then
  for ee = ES[i - 1], ES[i] - 1 do local j = E[ee]; if G.flag[j] ~= 2 then local s2 = sts[j]
    if s2.fixed[e] and s2.pos[e] == A.washIn then
      local k = L.cfg(A, sts[i]) .. " → " .. L.cfg(A, s2) .. (A.good[j] == 1 and " ЖИВОЕ" or (A.VL.newbie[j] and " видимо" or " скрыто"))
      agg[k] = (agg[k] or 0) + 1 end end end
end end
for k, v in pairs(agg) do print("  " .. k, v) end
