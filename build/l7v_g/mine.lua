-- build/l7v_g/mine.lua файл.lua — «минное поле»: по шагам кратчайших путей — допустимых ходов, в живое / скрытое / видимое;
-- по всем живым состояниям — доля ходов в проигрыш; ошибки подсказки №1 (угольник в столбе/дыре до ниппеля в устье).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local VL = V.compute(lvl, G, def, good)
local ES, E, flag, n = G.eStart.p, G.edges.p, G.flag, G.n
local cnt = {} for i = 1, n + 1 do cnt[i] = 0 end
for i = 1, n do for e = ES[i-1], ES[i]-1 do cnt[E[e]] = cnt[E[e]] + 1 end end
local st, s = {}, 1 for i = 1, n do st[i] = s; s = s + cnt[i] end st[n+1] = s
local fill, rv = {}, {} for i = 1, n do fill[i] = st[i] end
for i = 1, n do for e = ES[i-1], ES[i]-1 do local j = E[e]; rv[fill[j]] = i; fill[j] = fill[j] + 1 end end
local dw, q, h = {}, {}, 1
for i = 1, n do if flag[i] == 1 then dw[i] = 0; q[#q+1] = i end end
while h <= #q do local j = q[h]; h = h + 1; for k = st[j], st[j+1]-1 do local i = rv[k]; if dw[i] == nil then dw[i] = dw[j] + 1; q[#q+1] = i end end end
local opt = G.depth[G.firstWin]
local function hid(j) return flag[j] == 0 and good[j] ~= 1 and not VL.newbie[j] end
-- 1) по фазам кратчайших путей
local ph = {}
for i = 1, n do if flag[i] == 0 and dw[i] and G.depth[i] + dw[i] == opt then
  local d = G.depth[i]; local a = ph[d] or { st = 0, all = 0, live = 0, hid = 0, vis = 0 }; ph[d] = a
  a.st = a.st + 1
  for e = ES[i-1], ES[i]-1 do local j = E[e]; a.all = a.all + 1
    if good[j] == 1 or flag[j] == 1 then a.live = a.live + 1 elseif hid(j) then a.hid = a.hid + 1 else a.vis = a.vis + 1 end end
end end
print("фаза | состояний кратчайших | ходов всего | в живое | в скрытое | в видимое")
local T = { all = 0, live = 0, hid = 0, vis = 0 }
for d = 0, opt - 1 do local a = ph[d]; if a then
  print(string.format("  %2d  %d  %3d  %3d  %2d  %2d", d, a.st, a.all, a.live, a.hid, a.vis))
  T.all = T.all + a.all; T.live = T.live + a.live; T.hid = T.hid + a.hid; T.vis = T.vis + a.vis end end
print(string.format("итого по кратчайшим: ходов %d, в проигрыш %d (%.1f %%), из них скрытых %d", T.all, T.hid + T.vis, 100 * (T.hid + T.vis) / T.all, T.hid))
-- 2) по всем живым
local A = { all = 0, live = 0, hid = 0, vis = 0, stDoor = 0, stN = 0 }
for i = 1, n do if flag[i] == 0 and good[i] == 1 then
  A.stN = A.stN + 1; local dd = false
  for e = ES[i-1], ES[i]-1 do local j = E[e]; A.all = A.all + 1
    if good[j] == 1 or flag[j] == 1 then A.live = A.live + 1 elseif hid(j) then A.hid = A.hid + 1; dd = true else A.vis = A.vis + 1; dd = true end end
  if dd then A.stDoor = A.stDoor + 1 end
end end
print(string.format("все живые: состояний %d, ходов %d (%.2f на состояние), в проигрыш %d (%.2f %%: скрытых %d, видимых %d); живых с хотя бы одной дверью %d (%.1f %%)",
  A.stN, A.all, A.all / A.stN, A.hid + A.vis, 100 * (A.hid + A.vis) / A.all, A.hid, A.vis, A.stDoor, 100 * A.stDoor / A.stN))
-- 3) ошибка подсказки №1: из живого в мёртвое, угольник в столбе/дыре (x = 9, y = 4..6), ниппель не прикручен в устье
local qe, qn
for k, p in ipairs(lvl.pieces) do if p.tag == "elb" then qe = k elseif p.tag == "nip" then qn = k end end
local off, qq = {}, {}
for i = 1, n do if dw[i] and G.depth[i] + dw[i] == opt then off[i] = 0; qq[#qq+1] = i end end
h = 1
while h <= #qq do local u = qq[h]; h = h + 1
  for e = ES[u-1], ES[u]-1 do local v = E[e]; if good[v] == 1 and off[v] == nil then off[v] = off[u] + 1; qq[#qq+1] = v end end end
local function region(j)
  local d, qx, hx, maxd = { [j] = 0 }, { j }, 1, 0
  while hx <= #qx do local u = qx[hx]; hx = hx + 1
    for e = ES[u-1], ES[u]-1 do local v = E[e]; if hid(v) and d[v] == nil then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; qx[#qx+1] = v end end end
  return maxd, #qx
end
local agg = {}
for i = 1, n do if flag[i] == 0 and good[i] == 1 then
  for e = ES[i-1], ES[i]-1 do local j = E[e]
    if flag[j] == 0 and good[j] ~= 1 then
      local s2 = R.decode(lvl, G.keys[j])
      local x, y = R.xy(lvl, s2.pos[qe])
      local nx, ny = R.xy(lvl, s2.pos[qn])
      if x == 9 and y >= 4 and y <= 6 and not (s2.fixed[qn] and nx == 9 and ny == 6) then
        local k = string.format("угольник (9,%d)%s, %s", y, s2.fixed[qe] and " прикручен" or "", hid(j) and "СКРЫТ" or "видим")
        local a = agg[k] or { n = 0, off = 99, ph = 99, deep = 0 }; agg[k] = a
        a.n = a.n + 1; a.off = math.min(a.off, off[i] or 99); a.ph = math.min(a.ph, G.depth[i])
        if hid(j) then local d = region(j); if d > a.deep then a.deep = d end end
      end
    end end end end
print("ошибка подсказки №1 (угольник в столб/дыру до ниппеля): класс | входов | удаление от кратчайших | мин. ход | глубина")
for k, a in pairs(agg) do print(string.format("  %-34s вх %3d уд %2d ход≥%2d гл %2d", k, a.n, a.off, a.ph, a.deep)) end
SV.freeGraph(G); require("ffi").C.free(good)
