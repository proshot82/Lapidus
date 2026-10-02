-- build/l9v2/persist.lua файл.lua — стойкость единственной ошибки плана с пути (заглушка закреплена в ближнем выходе):
-- от каждой двери с кратчайших путей и в 1–2 ходах от них — мин. ходов по проигранным состояниям до «момента правды»:
--   (б') голова прикручена к дальнему выходу и Лапидус вытянут на полную длину (до ванны не хватает),
--   (в)  ноги прикручены к ванне при полной длине (голове не хватает до выхода),
--   (г)  тройник уже в гнезде и затем (б') или (в) — ложный план выполнен целиком;
-- для сравнения — на верном пути: сколько ходов от шагов 12–13 до финала. Только метрики.
local L = dofile("build/l9v2/lib.lua")
local S = L.load(arg[1])
local R = L.R
local lvl = S.lvl
local tags, bathQ = {}, nil
for q, p in ipairs(lvl.pieces) do if p.tag then tags[p.tag] = q end; if p.what == "bath" then bathQ = q end end
local sock = R.idx(lvl, 10, 7)
local sp, dw = S:onShortest(), S:distWin()
local off, q, h = {}, {}, 1
for i = 1, S.n do if sp[i] then off[i] = 0; q[#q+1] = i end end
while h <= #q do local u = q[h]; h = h + 1
  for e = S.ES[u-1], S.ES[u]-1 do local v = S.E[e]
    if S:live(v) and off[v] == nil then off[v] = off[u] + 1; q[#q+1] = v end end end
local function Bp(x) local pc = R.occupancy(x); return #x.body == lvl.Lmax and R.endScrew(lvl, x, pc, "head") == tags.m2 end
local function C(x) local pc = R.occupancy(x); return #x.body == lvl.Lmax and R.endScrew(lvl, x, pc, "heel") == bathQ end
local function teeIn(x) return x.pos[tags.tee] == sock and x.fixed[tags.tee] end
local function bfs(j, pred)
  if pred(S:st(j)) then return 0 end
  local d, qq, hh = { [j] = 0 }, { j }, 1
  while hh <= #qq do local u = qq[hh]; hh = hh + 1
    for e = S.ES[u-1], S.ES[u]-1 do local v = S.E[e]
      if S.flag[v] == 0 and not S:live(v) and d[v] == nil then
        d[v] = d[u] + 1
        if pred(S:st(v)) then return d[v] end
        qq[#qq+1] = v end end end
  return nil
end
print("дверь: шаг пути / удаление | (б') голова на дальнем, полная длина | (в) ноги в ванне, полная длина | (г) тройник в гнезде, затем (б') или (в) | до финала по верному пути от той же точки")
for i = 1, S.n do if S.flag[i] == 0 and S:live(i) and off[i] and off[i] <= 2 then
  for e = S.ES[i-1], S.ES[i]-1 do local j = S.E[e]
    if S:hid(j) then
      local g = bfs(j, function(x) return teeIn(x) and (Bp(x) or C(x)) end)
      print(string.format("  шаг %2d / %d | %s | %s | %s | %d", S.G.depth[i], off[i], tostring(bfs(j, Bp) or "—"), tostring(bfs(j, C) or "—"), tostring(g or "—"), dw[i]))
    end end end end
S:free()
