-- build/l9v2/offs.lua файл.lua — для каждого класса скрытых (разметка файла): мин. удаление двери от кратчайших путей
-- (ходов по живым) и мин. шаг пути, от которого до неё ближе всего. Только метрики.
local L = dofile("build/l9v2/lib.lua")
local S = L.load(arg[1])
local sp = S:onShortest()
local off, ph, q, h = {}, {}, {}, 1
for i = 1, S.n do if sp[i] then off[i] = 0; ph[i] = S.G.depth[i]; q[#q+1] = i end end
while h <= #q do local u = q[h]; h = h + 1
  for e = S.ES[u-1], S.ES[u]-1 do local v = S.E[e]
    if S:live(v) and off[v] == nil then off[v] = off[u] + 1; ph[v] = ph[u]; q[#q+1] = v end end end
local best = {}
for i = 1, S.n do if S.flag[i] == 0 and S:live(i) then
  for e = S.ES[i-1], S.ES[i]-1 do local j = S.E[e]
    if S:hid(j) then local s = S:st(j); local k = (S:wet(s) and "мокро " or "сухо ") .. S:fixedSig(s)
      local b = best[k]; local o = (off[i] or 99) + 1
      if not b or o < b[1] then best[k] = { o, ph[i] or -1 } end end end end end
for k, b in pairs(best) do print(string.format("  %-36s дверь в %d ходах от кратчайших (у шага %d)", k, b[1], b[2])) end
S:free()
