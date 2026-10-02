-- build/l10v/cls.lua файл.lua — классы скрытых тупиков o34 по механизму (разметка файла и файл+Y): размер (% от скрытых+живых),
-- скрыты ли знатоку, дверей из живых, мин. удаление двери от кратчайших путей (ходов по живым), шаги пути с дверями.
-- Механизм: что закреплено «не так» и где тройник относительно переходника (порядок схода с полки). Только метрики.
local L = dofile("build/l10v/lib.lua")
local S = L.load(arg[1])
local R = L.R
local lvl = S.lvl
local tags, sinkQ = {}, nil
for q, p in ipairs(lvl.pieces) do if p.tag then tags[p.tag] = q end; if p.what == "sink" then sinkQ = q end end
local toilet, srcC = R.idx(lvl, 10, 5), R.idx(lvl, 6, 7)
local Y = {}
for i = 1, S.n do if S.flag[i] ~= 2 then local s = S:st(i)
  Y[i] = S.VL.newbie[i] or (not S:live(i) and s.pos[tags.tee] == srcC and s.fixed[tags.tee] and not R.water(lvl, s).wet[sinkQ]) end end
local function zone(s, tg) local c = s.pos[tags[tg]]; local x, y = R.xy(lvl, c)
  if y <= 3 then return "полка" elseif y == 4 then return "дыра" elseif y == 5 then return "карниз" else return "колодец/тоннель" end end
local function key(s)
  if s.fixed[tags.nip] and s.pos[tags.nip] == toilet then return "A1 ниппель закреплён у унитаза" end
  if s.fixed[tags.adp] and s.pos[tags.adp] == toilet then return "A2 переходник закреплён у унитаза" end
  if s.pos[tags.tee] == srcC and s.fixed[tags.tee] then return "B0 тройник закрыл колодец, мойка сухая" end
  return "B1 колодец открыт; тройник: " .. zone(s, "tee") .. ", переходник: " .. zone(s, "adp")
end
local sp = S:onShortest()
local off, q, h = {}, {}, 1
for i = 1, S.n do if sp[i] then off[i] = 0; q[#q+1] = i end end
while h <= #q do local u = q[h]; h = h + 1
  for e = S.ES[u-1], S.ES[u]-1 do local v = S.E[e]
    if S:live(v) and off[v] == nil then off[v] = off[u] + 1; q[#q+1] = v end end end
local live, hidF, hidY = 0, 0, 0
local C = {}
for i = 1, S.n do if S.flag[i] ~= 2 then
  if S:live(i) then live = live + 1 elseif not S.VL.newbie[i] then hidF = hidF + 1
    local k = key(S:st(i)); local c = C[k] or { f = 0, y = 0, ex = 0, d = 0, off = 99, ph = {} }; C[k] = c
    c.f = c.f + 1; if not Y[i] then c.y = c.y + 1; hidY = hidY + 1 end; if not S.VL.expert[i] then c.ex = c.ex + 1 end end end end
for i = 1, S.n do if S.flag[i] == 0 and S:live(i) then
  for e = S.ES[i-1], S.ES[i]-1 do local j = S.E[e]
    if S:hid(j) then local c = C[key(S:st(j))]; c.d = c.d + 1
      local o = off[i] or 99; if o < c.off then c.off = o end
      if o == 0 then c.ph[S.G.depth[i]] = true end end end end end
print(string.format("живых %d; скрытых по файлу %d (%.1f %%), по файл+Y %d (%.1f %%)", live, hidF, 100 * hidF / (hidF + live), hidY, 100 * hidY / (hidY + live)))
print("класс | скрытых файл (% от скр+жив) | из них скрыты и при Y | скрыты знатоку | дверей | мин. удаление двери от кратчайших | шаги пути")
local l = {}
for k, c in pairs(C) do l[#l+1] = { k, c } end
table.sort(l, function(a, b) return a[1] < b[1] end)
for _, x in ipairs(l) do local c = x[2]
  local ph = {}; for p in pairs(c.ph) do ph[#ph+1] = p end; table.sort(ph)
  print(string.format("  %-58s %5d (%4.1f %%)  Y %5d (%4.1f %%)  зн %5d  дв %4d  уд %s  [%s]", x[1], c.f, 100 * c.f / (hidF + live), c.y, 100 * c.y / (hidY + live), c.ex, c.d,
    c.off < 99 and tostring(c.off) or "—", table.concat(ph, ","))) end
S:free()
