-- build/l4v2/reveal.lua — «время до прозрения» по классам: от входа в скрытый класс — минимум ходов до контакта/видимого,
-- максимум блуждания (глубина). Только метрики.
package.path = "./?.lua;" .. package.path
local AN2 = dofile("build/l4v2/an2.lua")
local A = _G.AN
local R = require("core.rules")
local G, good, VL, sts, lvl, cls = A.G, A.good, A.VL, A.sts, A.lvl, A.classes
local ES, E, flag = G.eStart.p, G.edges.p, G.flag
local cell, xy, qc, qn = A.cell, A.xy, A.qc, A.qn
local classOf = AN2.classOf
-- для каждого класса: входы (рёбра живое -> скрытое этого класса); по каждому входу BFS по скрытым:
-- minVis — минимум ходов до видимого проигрыша; minContact (для A) — до состояния, где муфта вплотную слева от ниппеля
local function bfs(j)
  local d, q, h = { [j] = 0 }, { j }, 1
  local minVis, minC, maxd, events = nil, nil, 0, 0
  while h <= #q do local u = q[h]; h = h + 1
    local su = sts[u]
    if su.pos[qc] == cell(7, 6) and su.pos[qn] == cell(8, 6) and minC == nil then minC = d[u] end
    for e = ES[u - 1], ES[u] - 1 do local v = E[e]
      if flag[v] ~= 2 and VL.newbie[v] and minVis == nil then minVis = d[u] + 1 end
      if A.hidden[v] and d[v] == nil then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; q[#q + 1] = v end
    end
  end
  return minVis or -1, minC or -1, maxd, #q
end
local agg = {}
for i = 1, G.n do if good[i] == 1 and flag[i] ~= 2 then
  for e = ES[i - 1], ES[i] - 1 do local j = E[e]
    if A.hidden[j] then local k = classOf(j)
      local mv, mc, md, sz = bfs(j)
      local t = agg[k] or { n = 0, mv = {}, mc = {}, md = 0, sz = 0 }; agg[k] = t
      t.n = t.n + 1; t.mv[#t.mv + 1] = mv; t.mc[#t.mc + 1] = mc; if md > t.md then t.md = md end; if sz > t.sz then t.sz = sz end
    end end end end
local function stat(a) table.sort(a); return string.format("мин %d, медиана %d, макс %d", a[1], a[math.ceil(#a / 2)], a[#a]) end
for k, t in pairs(agg) do
  print(string.format("%s: дверей %d | до видимого проигрыша: %s | до «муфта вплотную к ниппелю»: %s | глубина max %d | область max %d",
    cls[k][1], t.n, stat(t.mv), stat(t.mc), t.md, t.sz))
end
