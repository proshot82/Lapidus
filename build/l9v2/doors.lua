-- build/l9v2/doors.lua файл.lua [Y] — двери (живое → скрытое) по классам: число, удаление от кратчайших путей (BFS по живым),
-- фазы пути (для удаления ≤ 2), глубина скрытой области, мин. ходов до видимого; стойкость как естественное продолжение:
-- мин. ходов по проигранным состояниям до «момента правды» —
--   (а) тройник закреплён в гнезде линии унитаза (ложный план «идёт»),
--   (б) голова прикручена к дальнему выходу гребёнки (m2),
--   (в) ноги прикручены к ванне при полной длине.
-- С аргументом Y — разметка файл+Y (тройник закреплён не в гнезде). Только метрики.
local L = dofile("build/l9v2/lib.lua")
local S = L.load(arg[1])
local R = L.R
local lvl = S.lvl
local tags, bathQ = {}, nil
for q, p in ipairs(lvl.pieces) do if p.tag then tags[p.tag] = q end; if p.what == "bath" then bathQ = q end end
local sock = R.idx(lvl, 10, 7)
local arr = S.VL.newbie
if arg[2] == "Y" then
  arr = {}
  for i = 1, S.n do if S.flag[i] ~= 2 then local s = S:st(i)
    arr[i] = S.VL.newbie[i] or (not S:live(i) and s.pos[tags.tee] ~= 0 and s.fixed[tags.tee] and s.pos[tags.tee] ~= sock) end end
end
local sp = S:onShortest()
local off, ph, q, h = {}, {}, {}, 1
for i = 1, S.n do if sp[i] then off[i] = 0; ph[i] = { [S.G.depth[i]] = true }; q[#q+1] = i end end
while h <= #q do local u = q[h]; h = h + 1
  for e = S.ES[u-1], S.ES[u]-1 do local v = S.E[e]
    if S:live(v) and off[v] == nil then off[v] = off[u] + 1; ph[v] = ph[u]; q[#q+1] = v end end end
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
local PA = function(x) return x.pos[tags.tee] == sock and x.fixed[tags.tee] end
local PB = function(x) local pc = R.occupancy(x); return R.endScrew(lvl, x, pc, "head") == tags.m2 end
local PC = function(x) local pc = R.occupancy(x); return #x.body == lvl.Lmax and R.endScrew(lvl, x, pc, "heel") == bathQ end
local function key(s) return (S:wet(s) and "мокро " or "сухо ") .. S:fixedSig(s) end
local agg = {}
for i = 1, S.n do if S.flag[i] == 0 and S:live(i) then
  for e = S.ES[i-1], S.ES[i]-1 do local j = S.E[e]
    if S:hid(j, arr) then
      local k = key(S:st(j))
      local a = agg[k] or { n = 0, off = 99, ph = {}, deep = 0, rmin = 99, rmax = -1, cnt = {}, pa = {}, pb = {}, pc = {} }
      agg[k] = a
      a.n = a.n + 1
      local o = off[i] or 99
      a.cnt[o] = (a.cnt[o] or 0) + 1
      if o < a.off then a.off = o end
      if o <= 2 then
        for p in pairs(ph[i]) do a.ph[p] = true end
        local md = S:region(j, arr); if md > a.deep then a.deep = md end
        local r = S:reveal(j, arr) or 99; if r < a.rmin then a.rmin = r end; if r > a.rmax then a.rmax = r end
        a.pa[#a.pa+1] = bfs(j, PA) or -1; a.pb[#a.pb+1] = bfs(j, PB) or -1; a.pc[#a.pc+1] = bfs(j, PC) or -1
      end
    end end end end
print(arg[2] == "Y" and "разметка: файл+Y" or "разметка: файл (как у автора)")
print("класс входа | дверей | по удалению 0/1/2/3+ | фазы (удаление ≤ 2) | глубина | до видимого | до (а) тройник в гнезде | (б) голова на m2 | (в) ноги в ванне при полной длине")
local l = {}
for k, a in pairs(agg) do l[#l+1] = { k, a } end
table.sort(l, function(x, y) return x[2].off < y[2].off or (x[2].off == y[2].off and x[2].n > y[2].n) end)
local function mm(t) local lo, hi = 99, -1; for _, v in ipairs(t) do if v >= 0 then lo = math.min(lo, v); hi = math.max(hi, v) end end
  return hi < 0 and "—" or (lo .. "–" .. hi) end
for _, x in ipairs(l) do local k, a = x[1], x[2]
  local p = {}
  for v in pairs(a.ph) do p[#p+1] = v end
  table.sort(p)
  local c3 = 0
  for o, c in pairs(a.cnt) do if o >= 3 then c3 = c3 + c end end
  print(string.format("  %-34s %4d  %d/%d/%d/%d  [%s]  гл %s  вскр %s | (а) %s (б) %s (в) %s", k, a.n, a.cnt[0] or 0, a.cnt[1] or 0, a.cnt[2] or 0, c3,
    table.concat(p, ","), a.rmax >= 0 and tostring(a.deep) or "-", a.rmax >= 0 and (a.rmin .. "–" .. a.rmax) or "-", mm(a.pa), mm(a.pb), mm(a.pc)))
end
-- на верном пути: через сколько ходов от шагов 12–13 тройник в гнезде и ноги в ванне (для сравнения)
S:free()
