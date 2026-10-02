-- build/l4v2/an2.lua — подклассы L, двери из живых в скрытые, положение дверей на кратчайших путях, подсказка №1.
package.path = "./?.lua;" .. package.path
arg = { "build/l4d/k40.lua", arg[1] or "-" }
local A = dofile("build/l4v2/an.lua")
local R = require("core.rules")
local G, good, VL, sts, lvl = A.G, A.good, A.VL, A.sts, A.lvl
local qc, qn, B, cell, xy, cls = A.qc, A.qn, A.B, A.cell, A.xy, A.classes
local ES, E, flag = G.eStart.p, G.edges.p, G.flag
local function classOf(i) for k, c in ipairs(cls) do if c[2](sts[i]) then return k end end return 99 end
-- подклассы L по муфте
local sub = {}
for i in pairs(A.hidden) do if classOf(i) == 3 then local st = sts[i]
  local k = (st.fixed[qc] and st.pos[qc] == B) and "муфта на стояке" or ((select(2, xy(st.pos[qc])) == 3) and "муфта на антресоли" or "муфта внизу, свободна")
  sub[k] = (sub[k] or 0) + 1 end end
print("подклассы L:"); for k, v in pairs(sub) do print("  " .. k, v) end
-- двери: рёбра живое -> скрытое
local doors, doorCls, doorStates = 0, {}, {}
for i = 1, G.n do if flag[i] ~= 2 and good[i] == 1 then
  for e = ES[i - 1], ES[i] - 1 do local j = E[e]
    if A.hidden[j] then doors = doors + 1; local k = classOf(j); doorCls[k] = (doorCls[k] or 0) + 1; doorStates[i] = true end
  end end end
local nds = 0; for _ in pairs(doorStates) do nds = nds + 1 end
print(string.format("дверей живое->скрытое: %d рёбер из %d живых состояний", doors, nds))
for k, v in pairs(doorCls) do print("  класс " .. (cls[k] and cls[k][1] or k), v) end
-- кратчайшие пути: расстояние от старта и до выигрыша по живым
local opt = G.depth[G.firstWin]
local dist = {}
for i = 1, G.n do dist[i] = G.depth[i] end
-- обратное расстояние до выигрыша (по всем рёбрам)
local rs, rv = {}, {}
local cnt = {}
for i = 1, G.n do cnt[i] = 0 end
for i = 1, G.n do for e = ES[i - 1], ES[i] - 1 do local j = E[e]; cnt[j] = cnt[j] + 1 end end
local st0, s = {}, 1
for i = 1, G.n do st0[i] = s; s = s + cnt[i] end; st0[G.n + 1] = s
local fill = {}; for i = 1, G.n do fill[i] = st0[i] end
for i = 1, G.n do for e = ES[i - 1], ES[i] - 1 do local j = E[e]; rv[fill[j]] = i; fill[j] = fill[j] + 1 end end
local toWin, q, h = {}, {}, 1
for i = 1, G.n do if flag[i] == 1 then toWin[i] = 0; q[#q + 1] = i end end
while h <= #q do local j = q[h]; h = h + 1
  for k = st0[j], st0[j + 1] - 1 do local i = rv[k]; if toWin[i] == nil and flag[i] ~= 2 then toWin[i] = toWin[j] + 1; q[#q + 1] = i end end end
-- состояния на кратчайших: depth + toWin == opt
local onSP = {}
local nsp = 0
for i = 1, G.n do if toWin[i] and G.depth[i] + toWin[i] == opt then onSP[i] = true; nsp = nsp + 1 end end
print("состояний на кратчайших путях: " .. nsp)
-- двери с кратчайших путей: по шагу и классу; «независимые ошибки» — различные (класс, конфигурация деталей после хода)
local byStep, errs = {}, {}
for i in pairs(onSP) do
  for e = ES[i - 1], ES[i] - 1 do local j = E[e]
    if A.hidden[j] then
      local k = classOf(j)
      local d = G.depth[i]
      byStep[d] = byStep[d] or {}
      byStep[d][k] = (byStep[d][k] or 0) + 1
      local st = sts[j]; local xc, yc = xy(st.pos[qc]); local xn, yn = xy(st.pos[qn])
      local key = string.format("%s: cpl(%d,%d)%s nip(%d,%d)", cls[k][1]:sub(1, 2), xc, yc, st.fixed[qc] and "F" or "", xn, yn)
      errs[key] = (errs[key] or 0) + 1
    end
  end
end
print("двери со всех кратчайших путей по шагам (шаг: класс=число рёбер):")
for d = 0, opt do if byStep[d] then local t = {}
  for k, v in pairs(byStep[d]) do t[#t + 1] = cls[k][1]:sub(1, 2) .. "=" .. v end
  print(string.format("  шаг %2d: %s", d, table.concat(t, " "))) end end
print("различные конфигурации деталей сразу после ошибки с кратчайшего пути:")
for k, v in pairs(errs) do print("  " .. k, v) end
-- двери в L по расстоянию от кратчайших путей (по живым)
local dSP, qq = {}, {}
for i in pairs(onSP) do dSP[i] = 0; qq[#qq + 1] = i end
h = 1
while h <= #qq do local i = qq[h]; h = h + 1
  for e = ES[i - 1], ES[i] - 1 do local j = E[e]; if good[j] == 1 and dSP[j] == nil then dSP[j] = dSP[i] + 1; qq[#qq + 1] = j end end end
local mind = {}
for i = 1, G.n do if good[i] == 1 and flag[i] ~= 2 then
  for e = ES[i - 1], ES[i] - 1 do local j = E[e]; if A.hidden[j] then local k = classOf(j)
    if dSP[i] and (mind[k] == nil or dSP[i] < mind[k]) then mind[k] = dSP[i] end end end end end
for k, v in pairs(mind) do print(string.format("ближайшая к кратчайшим путям дверь в класс %s: %d ходов по живым", cls[k][1], v)) end
-- «время до прозрения»: из скрытого состояния — минимальное число ходов до видимого, и максимум среди входов класса
local function revealDepth(j)
  -- максимальное расстояние внутри скрытой области (как в vislib) и минимальное до видимого
  local d, qx, hx, maxd = { [j] = 0 }, { j }, 1, 0
  while hx <= #qx do local u = qx[hx]; hx = hx + 1
    for e = ES[u - 1], ES[u] - 1 do local v = E[e]
      if A.hidden[v] and d[v] == nil then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; qx[#qx + 1] = v end end end
  return maxd, #qx
end
local seen = {}
for i in pairs(onSP) do for e = ES[i - 1], ES[i] - 1 do local j = E[e]
  if A.hidden[j] and not seen[j] then seen[j] = true
    local md, sz = revealDepth(j)
    print(string.format("  вход с кратчайшего пути (шаг %d) в класс %s: глубина %d, размер области %d", G.depth[i], cls[classOf(j)][1]:sub(1, 2), md, sz)) end end end
-- сколько событий с деталями можно сделать в классе A, не вскрыв проигрыш: сдвиги муфты
return { onSP = onSP, toWin = toWin, classOf = classOf, dSP = dSP }
