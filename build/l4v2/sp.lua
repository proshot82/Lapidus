-- build/l4v2/sp.lua — кратчайшие и почти кратчайшие решения: ширина по шагам, различие конфигураций деталей,
-- обязательность приёма (муфта закреплена до того, как ниппель покинул антресоль), число решений opt..opt+3.
-- Печатает только счётчики (без ходов).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1] or "build/l4d/k40.lua")
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local ES, E, flag = G.eStart.p, G.edges.p, G.flag
local opt = G.depth[G.firstWin]
local qc, qn, S
for q, p in ipairs(lvl.pieces) do if p.what == "coupling" then qc = q elseif p.what == "nipple" then qn = q end; if p.source then S = p.start end end
local B = lvl.nb[S][1]
local sts = {}
local function st(i) sts[i] = sts[i] or R.decode(lvl, G.keys[i]); return sts[i] end
-- обратное расстояние до выигрыша
local cnt = {}
for i = 1, G.n do cnt[i] = 0 end
for i = 1, G.n do for e = ES[i - 1], ES[i] - 1 do cnt[E[e]] = cnt[E[e]] + 1 end end
local off, s = {}, 1
for i = 1, G.n do off[i] = s; s = s + cnt[i] end; off[G.n + 1] = s
local fill, rv = {}, {}
for i = 1, G.n do fill[i] = off[i] end
for i = 1, G.n do for e = ES[i - 1], ES[i] - 1 do local j = E[e]; rv[fill[j]] = i; fill[j] = fill[j] + 1 end end
local toWin, q, h = {}, {}, 1
for i = 1, G.n do if flag[i] == 1 then toWin[i] = 0; q[#q + 1] = i end end
while h <= #q do local j = q[h]; h = h + 1
  for k = off[j], off[j + 1] - 1 do local i = rv[k]; if toWin[i] == nil and flag[i] == 0 then toWin[i] = toWin[j] + 1; q[#q + 1] = i end end end
local function pieces(i) local x = st(i); local t = {}
  for _, qq in ipairs({ qc, qn }) do t[#t + 1] = x.pos[qq] .. (x.fixed[qq] and "F" or "") end; return table.concat(t, ",") end
-- по шагам: число состояний на кратчайших и число разных конфигураций деталей
print("кратчайшие: шаг -> состояний / разных раскладок деталей")
local line = {}
for d = 0, opt do
  local n, cfg, nc = 0, {}, 0
  for i = 1, G.n do if G.depth[i] == d and toWin[i] and d + toWin[i] == opt then n = n + 1
    local k = pieces(i); if not cfg[k] then cfg[k] = true; nc = nc + 1 end end end
  line[#line + 1] = n .. "/" .. nc
end
print("  " .. table.concat(line, " "))
-- решения до opt+K: считаем число последовательностей (пути по рёбрам в DAG «остаток <= бюджет»)
local memo = {}
local function count(i, budget)
  if flag[i] == 1 then return 1 end
  if not toWin[i] or toWin[i] > budget then return 0 end
  local key = i * 8 + budget
  if memo[key] then return memo[key] end
  local c = 0
  for e = ES[i - 1], ES[i] - 1 do local j = E[e]; if flag[j] ~= 2 then c = c + count(j, budget - 1) end end
  memo[key] = c; return c
end
for k = 0, 3 do print(string.format("решений длины ≤ opt+%d: %d", k, count(1, opt + k))) end
-- инвариант приёма на всех решениях ≤ opt+3: в момент, когда ниппель впервые сдвинулся со стартовой клетки, муфта уже закреплена на стояке;
-- и ниппель спускается не через люк (x=6)
local viol, total = 0, 0
local nipStart = lvl.pieces[qn].start
local function walk(i, budget, nipMoved, bad)
  if flag[i] == 1 then total = total + 1; if bad then viol = viol + 1 end return end
  if not toWin[i] or toWin[i] > budget then return end
  for e = ES[i - 1], ES[i] - 1 do local j = E[e]
    if flag[j] ~= 2 then
      local sj = st(j)
      local nm, b = nipMoved, bad
      if not nm and sj.pos[qn] ~= nipStart then nm = true; if not (sj.fixed[qc] and sj.pos[qc] == B) then b = true end end
      walk(j, budget - 1, nm, b)
    end
  end
end
walk(1, opt + 3, false, false)
print(string.format("решений ≤ opt+3: %d, из них ниппель сдвинут до закрепления муфты: %d", total, viol))
-- различные итоговые раскладки Лапидуса в выигрышных состояниях длины opt
local fin = {}
local nf = 0
for i = 1, G.n do if flag[i] == 1 and G.depth[i] == opt then local x = st(i); local k = table.concat(x.body, "-"); if not fin[k] then fin[k] = true; nf = nf + 1 end end end
print("разных финальных поз Лапидуса на кратчайших: " .. nf)
local wins = 0; for i = 1, G.n do if flag[i] == 1 then wins = wins + 1 end end
print("выигрышных состояний всего: " .. wins)
