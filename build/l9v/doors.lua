-- build/l9v/doors.lua файл.lua [W] — двери (живое → скрытое) по классам: число, удаление от кратчайших путей
-- (BFS по живым от множества состояний всех кратчайших путей), ближайшая фаза пути, глубина скрытой области, мин. ходов до видимого.
-- С аргументом W — разметка линейка+W+T+S (build/l9v/alt.lua). Только метрики.
local L = dofile("build/l9v/lib.lua")
local S = L.load(arg[1])
local R = L.R
local lvl, W = S.lvl, S.lvl.W
local function idx(x, y) return (y - 1) * W + x end
local tags = {}
for q, p in ipairs(lvl.pieces) do if p.tag then tags[p.tag] = q end end
local function occ(s) local t = {} for q = 1, #s.pos do if s.pos[q] ~= 0 then t[s.pos[q]] = q end end return t end
local function ruleW(s)
  local o = occ(s)
  for q, p in ipairs(lvl.pieces) do if p.movable and s.pos[q] ~= 0 and s.fixed[q] then
    for d = 1, 4 do if p.ports[d] then
      local t = lvl.nb[s.pos[q]][d]
      if t == 0 or lvl.cell[t] == R.WALL then return true end
      local r = o[t]
      if r and s.fixed[r] and not R.match(p.ports[d], lvl.pieces[r].ports[R.OPP[d]]) then return true end
    end end end end
  return false
end
local function ruleT(s) local o = occ(s); local q = o[idx(9, 7)]; return q and s.fixed[q] and lvl.pieces[q].ports[R.RIGHT] ~= "V" or false end
local function ruleS(s)
  local o = occ(s)
  local bodyMinX = 99
  for _, c in ipairs(s.body) do local x, y = R.xy(lvl, c)
    if (y == 5 and x <= 5) or (x == 2 and (y == 6 or y == 7)) or y == 8 then bodyMinX = math.min(bodyMinX, (y == 5) and x or 0) end end
  for _, tg in ipairs({ "tee", "plug" }) do local q = tags[tg]
    if q and s.pos[q] ~= 0 and not s.fixed[q] then
      local x, y = R.xy(lvl, s.pos[q])
      local stacked = (x == 6 and y == 4 and o[idx(6, 5)] and not s.fixed[o[idx(6, 5)]])
      if ((y == 5 and x <= 6) or stacked) and not (bodyMinX < (stacked and 6 or x)) then return true end
    end end
  return false
end
local arr = S.VL.newbie
if arg[2] == "W" then
  arr = {}
  for i = 1, S.n do if S.flag[i] ~= 2 then local s = S:st(i); arr[i] = S.VL.newbie[i] or ((ruleW(s) or ruleT(s) or ruleS(s)) and not S:live(i)) end end
end
local sp, dw, opt = S:onShortest(), S:distWin(), S:opt()
-- удаление от кратчайших по живым + ближайшая фаза
local off, ph, q, h = {}, {}, {}, 1
for i = 1, S.n do if sp[i] then off[i] = 0; ph[i] = S.G.depth[i]; q[#q+1] = i end end
while h <= #q do local u = q[h]; h = h + 1
  for e = S.ES[u-1], S.ES[u]-1 do local v = S.E[e]
    if S:live(v) and off[v] == nil then off[v] = off[u] + 1; ph[v] = ph[u]; q[#q+1] = v end end end
local function key(s) return (S:wet(s) and "мокро " or "сухо ") .. S:fixedSig(s) end
local agg = {}
for i = 1, S.n do if S.flag[i] == 0 and S:live(i) then
  for e = S.ES[i-1], S.ES[i]-1 do local j = S.E[e]
    if S:hid(j, arr) then
      local k = key(S:st(j))
      local a = agg[k] or { n = 0, off = 99, ph = {}, deep = 0, rmin = 99, rmax = -1, cnt = {} }
      agg[k] = a
      a.n = a.n + 1
      local o = off[i] or 99
      a.cnt[o] = (a.cnt[o] or 0) + 1
      if o < a.off then a.off = o end
      if o <= 2 then
        a.ph[ph[i]] = true
        local md = S:region(j, arr); if md > a.deep then a.deep = md end
        local r = S:reveal(j, arr) or 99; if r < a.rmin then a.rmin = r end; if r > a.rmax then a.rmax = r end
      end
    end end end end
print(arg[2] == "W" and "разметка: линейка+W+T+S" or "разметка: линейка (как у автора)")
print("класс входа | дверей | по удалению от кратчайших 0/1/2/3+ | фазы пути (для удаления ≤ 2) | глубина | до видимого мин–макс")
local l = {}
for k, a in pairs(agg) do l[#l+1] = { k, a } end
table.sort(l, function(x, y) return x[2].off < y[2].off or (x[2].off == y[2].off and x[2].n > y[2].n) end)
for _, x in ipairs(l) do local k, a = x[1], x[2]
  local p = {}
  for v in pairs(a.ph) do p[#p+1] = v end
  table.sort(p)
  local c3 = 0
  for o, c in pairs(a.cnt) do if o >= 3 then c3 = c3 + c end end
  print(string.format("  %-36s %5d  %d/%d/%d/%d  [%s]  гл %s  вскр %s", k, a.n, a.cnt[0] or 0, a.cnt[1] or 0, a.cnt[2] or 0, c3,
    table.concat(p, ","), a.rmax >= 0 and tostring(a.deep) or "-", a.rmax >= 0 and (a.rmin .. "–" .. a.rmax) or "-"))
end
S:free()
