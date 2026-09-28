-- verify_census.lua файл.lua [грубо] — скептик кв. 7 (28.09): перепись состояний по классам положения деталей.
-- Для каждого класса: живых / мёртвых скрытых / мёртвых видимых (по visibleLoss файла) и ближайшая глубина.
-- Печатает только числа и названия классов (без ходов и кадров).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local coarse = arg[2] == "грубо"
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local Q = {}
for q, p in ipairs(lvl.pieces) do if p.tag then Q[p.tag] = q end end
local src
for _, p in ipairs(lvl.pieces) do if p.source then src = p.start end end
local sx, sy = R.xy(lvl, src)
local function region(st, q)
  local c = st.pos[q]
  if c == 0 then return "смыта" end
  local x, y = R.xy(lvl, c)
  local f = st.fixed[q] and "З" or ""
  if x < sx and y <= 3 then return "антресоль" .. f end
  if x == sx and y <= sy - lvl.R - 1 then return "над фонтаном" .. f end
  if x == sx then return "шахта" .. f end
  return "карман" .. f
end
local function lost(st)
  if not def.washOk then
    for q, p in ipairs(lvl.pieces) do if p.movable and st.pos[q] == 0 then return true end end
  end
  return def.visibleLoss and def.visibleLoss(lvl, st) or false
end
local function key(st)
  local t = {}
  t[#t + 1] = "угольник:" .. region(st, Q.elb)
  t[#t + 1] = "переходник:" .. region(st, Q.adp)
  t[#t + 1] = "муфта:" .. region(st, Q.cpl)
  if st.pos[Q.adp] ~= 0 and st.pos[Q.cpl] ~= 0 and st.asm[Q.adp] == st.asm[Q.cpl] then t[#t + 1] = "пара А+М" end
  if coarse then
    t = {}
    t[#t + 1] = st.fixed[Q.elb] and "фонтан заглушён" or "фонтан бьёт"
    t[#t + 1] = st.fixed[Q.adp] and "переходник в ванне" or "переходник свободен"
    t[#t + 1] = st.fixed[Q.cpl] and "муфта закреплена" or "муфта свободна"
    if st.pos[Q.adp] ~= 0 and st.pos[Q.cpl] ~= 0 and st.asm[Q.adp] == st.asm[Q.cpl] then t[#t + 1] = "пара А+М" end
  end
  return table.concat(t, " | ")
end
local agg, order = {}, {}
local tl, th, tv = 0, 0, 0
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local st = R.decode(lvl, G.keys[i])
    local k = key(st)
    local a = agg[k]
    if not a then a = { k = k, live = 0, hid = 0, vis = 0, dmin = 1e9 }; agg[k] = a; order[#order + 1] = a end
    if good[i] == 1 then a.live = a.live + 1; tl = tl + 1
    elseif lost(st) then a.vis = a.vis + 1; tv = tv + 1
    else a.hid = a.hid + 1; th = th + 1; if G.depth[i] < a.dmin then a.dmin = G.depth[i] end end
  end
end
table.sort(order, function(a, b) return a.hid > b.hid end)
print(string.format("всего: живых %d, скрытых %d, видимых %d  (скрытых %.0f %%)", tl, th, tv, 100 * th / (th + tl)))
for _, a in ipairs(order) do
  if a.hid > 0 or a.live > 0 then
    print(string.format("%6d скр %6d вид %6d жив  (ближ. скрытое на глуб. %s)  %s", a.hid, a.vis, a.live,
      a.dmin < 1e9 and tostring(a.dmin) or "—", a.k))
  end
end
SV.freeGraph(G); require("ffi").C.free(good)
