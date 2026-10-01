-- build/l9v/mine.lua файл.lua — «минное поле» и ширина для игрока: по шагам всех кратчайших путей — допустимых ходов,
-- в живое / скрытое / видимое (линейка); по всем живым — доля ходов в проигрыш, среднее число допустимых ходов.
local L = dofile("build/l9v/lib.lua")
local S = L.load(arg[1])
local sp, dw, opt = S:onShortest(), S:distWin(), S:opt()
local ph = {}
for i = 1, S.n do if sp[i] and S.flag[i] == 0 then
  local d = S.G.depth[i]; local a = ph[d] or { st = 0, all = 0, live = 0, hid = 0, vis = 0, prog = 0 }; ph[d] = a
  a.st = a.st + 1
  for e = S.ES[i-1], S.ES[i]-1 do local j = S.E[e]; a.all = a.all + 1
    if S:live(j) then a.live = a.live + 1; if dw[j] == dw[i] - 1 then a.prog = a.prog + 1 end
    elseif S:hid(j) then a.hid = a.hid + 1 else a.vis = a.vis + 1 end end
end end
print("шаг | состояний кратчайших | допустимых ходов | в живое (из них по кратчайшему) | в скрытое | в видимое")
local T = { all = 0, live = 0, hid = 0, vis = 0 }
local line = {}
for d = 0, opt - 1 do local a = ph[d]; if a then
  print(string.format("  %2d  %d  %2d  %2d (%d)  %d  %d", d, a.st, a.all, a.live, a.prog, a.hid, a.vis))
  T.all = T.all + a.all; T.live = T.live + a.live; T.hid = T.hid + a.hid; T.vis = T.vis + a.vis end end
print(string.format("итого по кратчайшим: ходов %d, в проигрыш %d (%.1f %%: скрытых %d, видимых %d)", T.all, T.hid + T.vis, 100 * (T.hid + T.vis) / T.all, T.hid, T.vis))
local A = { st = 0, all = 0, lose = 0, hid = 0, vis = 0, door = 0 }
local tot, nonterm = 0, 0
for i = 1, S.n do
  if S.flag[i] == 0 then nonterm = nonterm + 1; tot = tot + (S.ES[i] - S.ES[i-1]) end
  if S.flag[i] == 0 and S:live(i) then
    A.st = A.st + 1; local dd = false
    for e = S.ES[i-1], S.ES[i]-1 do local j = S.E[e]; A.all = A.all + 1
      if not S:live(j) then A.lose = A.lose + 1; dd = true; if S:hid(j) then A.hid = A.hid + 1 else A.vis = A.vis + 1 end end end
    if dd then A.door = A.door + 1 end
  end end
print(string.format("все живые: %d состояний, ходов %d (%.2f на состояние), в проигрыш %d (%.1f %%: скрытых %d, видимых %d); живых с выходом в проигрыш %d (%.1f %%)",
  A.st, A.all, A.all / A.st, A.lose, 100 * A.lose / A.all, A.hid, A.vis, A.door, 100 * A.door / A.st))
print(string.format("весь граф: нетерминальных %d, среднее допустимых ходов %.2f", nonterm, tot / nonterm))
-- сколько живых состояний на расстоянии ≤ k от кратчайших путей (по живым) — «ширина свободы» игрока
local off, q, h = {}, {}, 1
for i = 1, S.n do if sp[i] then off[i] = 0; q[#q+1] = i end end
while h <= #q do local u = q[h]; h = h + 1
  for e = S.ES[u-1], S.ES[u]-1 do local v = S.E[e]
    if S:live(v) and off[v] == nil then off[v] = off[u] + 1; q[#q+1] = v end end end
local hist = {}
for i, o in pairs(off) do hist[o] = (hist[o] or 0) + 1 end
local t, acc = {}, 0
for o = 0, 40 do if hist[o] then acc = acc + hist[o]; t[#t+1] = o .. ":" .. acc end end
print("живых в пределах k ходов от кратчайших (k:накопленно): " .. table.concat(t, " "))
S:free()
