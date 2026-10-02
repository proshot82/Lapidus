-- build/l10v/doors.lua файл.lua — двери (живое → скрытое) с ВСЕХ кратчайших путей o34: число кратчайших путей, по шагам —
-- сколько путей проходит через шаг с дверью, есть ли на каждом пути дверь во второй половине; классы дверей (механизм),
-- глубина скрытой области, ходов до видимого по разметке файла и файл+Y («мойка отрезана»); риск по пути
-- (доля проигрышных ходов из живых состояний на кратчайших путях). Только метрики, без ходов.
local L = dofile("build/l10v/lib.lua")
local S = L.load(arg[1])
local R = L.R
local lvl = S.lvl
local tags, sinkQ = {}, nil
for q, p in ipairs(lvl.pieces) do if p.tag then tags[p.tag] = q end; if p.what == "sink" then sinkQ = q end end
local toilet, srcC = R.idx(lvl, 10, 5), R.idx(lvl, 6, 7)
-- разметка файл+Y
local Y = {}
for i = 1, S.n do if S.flag[i] ~= 2 then local s = S:st(i)
  Y[i] = S.VL.newbie[i] or (not S:live(i) and s.pos[tags.tee] == srcC and s.fixed[tags.tee] and not R.water(lvl, s).wet[sinkQ]) end end
local function inTunnel(s, q) local c = s.pos[q]; if c == 0 then return false end; local x, y = R.xy(lvl, c); return y >= 6 and x <= 6 end
local function label(s)
  if s.fixed[tags.nip] and s.pos[tags.nip] == toilet then return "ниппель к унитазу" end
  if s.fixed[tags.adp] and s.pos[tags.adp] == toilet then return "переходник к унитазу" end
  if s.fixed[tags.tee] and s.pos[tags.tee] == srcC then
    if inTunnel(s, tags.adp) or inTunnel(s, tags.nip) then return "тройник закрыл, в тоннеле не всё" end
    return "тройник закрыл пустой тоннель" end
  if inTunnel(s, tags.adp) and not inTunnel(s, tags.nip) then return "переходник раньше ниппеля" end
  if inTunnel(s, tags.tee) then return "тройник в колодце (не закреплён)" end
  return "прочее: " .. S:cfg(s)
end
local opt, dw, sp = S:opt(), S:distWin(), S:onShortest()
-- число кратчайших путей через состояние: прямой и обратный счёт
local fw, bw = {}, {}
local byD = {}
for i = 1, S.n do if sp[i] then local d = S.G.depth[i]; byD[d] = byD[d] or {}; table.insert(byD[d], i) end end
fw[1] = 1
for d = 0, opt - 1 do for _, i in ipairs(byD[d] or {}) do
  for e = S.ES[i-1], S.ES[i]-1 do local j = S.E[e]
    if sp[j] and S.G.depth[j] == d + 1 then fw[j] = (fw[j] or 0) + (fw[i] or 0) end end end end
for d = opt, 0, -1 do for _, i in ipairs(byD[d] or {}) do
  if S.flag[i] == 1 then bw[i] = 1 else
    local c = 0
    for e = S.ES[i-1], S.ES[i]-1 do local j = S.E[e]
      if sp[j] and S.G.depth[j] == d + 1 then c = c + (bw[j] or 0) end end
    bw[i] = c end end end
local total = 0
for _, i in ipairs(byD[opt]) do if S.flag[i] == 1 then total = total + fw[i] end end
print(string.format("кратчайших путей %d (ходов %d); состояний на кратчайших %d", total, opt, (function() local c = 0; for _ in pairs(sp) do c = c + 1 end; return c end)()))
-- двери по шагам и пути без двери во второй половине (по файлу и по файл+Y)
local half = opt / 2
local function hasDoor(i, arr) for e = S.ES[i-1], S.ES[i]-1 do if S:hid(S.E[e], arr) then return true end end; return false end
for _, mk in ipairs({ { "файл", S.VL.newbie }, { "файл+Y", Y } }) do
  local arr = mk[2]
  local t = {}
  for d = 0, opt - 1 do local through = 0
    for _, i in ipairs(byD[d] or {}) do if hasDoor(i, arr) then through = through + fw[i] * bw[i] end end
    if through > 0 then t[#t+1] = string.format("%d:%d/%d", d, through, total) end end
  -- пути без двери во 2-й половине: DP по состояниям 2-й половины без дверей
  local nd = {}
  for d = opt, 0, -1 do for _, i in ipairs(byD[d] or {}) do
    if S.flag[i] == 1 then nd[i] = 1 else
      local ok = not (d >= half and hasDoor(i, arr))
      local c = 0
      if ok then for e = S.ES[i-1], S.ES[i]-1 do local j = S.E[e]
        if sp[j] and S.G.depth[j] == d + 1 then c = c + (nd[j] or 0) end end end
      nd[i] = c end end end
  local nf = {}
  for d = opt, 0, -1 do for _, i in ipairs(byD[d] or {}) do
    if S.flag[i] == 1 then nf[i] = 1 else
      local ok = not (d < half and hasDoor(i, arr))
      local c = 0
      if ok then for e = S.ES[i-1], S.ES[i]-1 do local j = S.E[e]
        if sp[j] and S.G.depth[j] == d + 1 then c = c + (nf[j] or 0) end end end
      nf[i] = c end end end
  print(string.format("[%s] шаг:путей через шаг с дверью/всех — %s", mk[1], table.concat(t, " ")))
  print(string.format("[%s] путей БЕЗ двери во 2-й половине (шаги ≥ %g): %d из %d; без двери в 1-й: %d из %d", mk[1], half, nd[1], total, nf[1], total))
end
-- классы дверей с кратчайших путей и в 1–2 ходах от них (по живым)
local off, q, h = {}, {}, 1
for i = 1, S.n do if sp[i] then off[i] = 0; q[#q+1] = i end end
while h <= #q do local u = q[h]; h = h + 1
  for e = S.ES[u-1], S.ES[u]-1 do local v = S.E[e]
    if S:live(v) and off[v] == nil then off[v] = off[u] + 1; q[#q+1] = v end end end
local agg = {}
for i = 1, S.n do if S.flag[i] == 0 and S:live(i) then
  for e = S.ES[i-1], S.ES[i]-1 do local j = S.E[e]
    if S:hid(j) then
      local k = label(S:st(j))
      local a = agg[k] or { n = 0, cnt = {}, steps = {}, deep = 0, r1 = {}, r2 = {}, mo = 99 }
      agg[k] = a
      a.n = a.n + 1
      local o = off[i] or 99
      if o < a.mo then a.mo = o end
      a.cnt[math.min(o, 3)] = (a.cnt[math.min(o, 3)] or 0) + 1
      if o == 0 then
        a.steps[S.G.depth[i]] = true
        local md = S:region(j); if md > a.deep then a.deep = md end
        a.r1[#a.r1+1] = S:reveal(j) or -1
        a.r2[#a.r2+1] = S:reveal(j, Y) or 0
      end
    end end end end
local function mm(t) local lo, hi = 99, -1; for _, v in ipairs(t) do if v >= 0 then lo = math.min(lo, v); hi = math.max(hi, v) end end
  return hi < 0 and "—" or (lo .. "–" .. hi) end
print("класс двери | рёбер живое→скрытое | по удалению от кратчайших 0/1/2/3+ | шаги (удаление 0) | глубина | до видимого: файл | файл+Y")
local l = {}
for k, a in pairs(agg) do l[#l+1] = { k, a } end
table.sort(l, function(x, y) return x[2].mo < y[2].mo or (x[2].mo == y[2].mo and x[2].n > y[2].n) end)
for _, x in ipairs(l) do local k, a = x[1], x[2]
  local st = {}
  for d in pairs(a.steps) do st[#st+1] = d end
  table.sort(st)
  print(string.format("  %-34s %4d  %d/%d/%d/%d  [%s]  гл %s  вскр %s | %s", k:sub(1, 120), a.n, a.cnt[0] or 0, a.cnt[1] or 0, a.cnt[2] or 0, a.cnt[3] or 0,
    table.concat(st, ","), #st > 0 and tostring(a.deep) or "-", mm(a.r1), mm(a.r2)))
end
-- риск по пути: из живых состояний на кратчайших путях — доля ходов в проигрыш (скрытый / видимый)
local mv, hd, vs, live = 0, 0, 0, 0
local perStep = {}
for d = 0, opt - 1 do local m2, h2 = 0, 0
  for _, i in ipairs(byD[d] or {}) do
    for e = S.ES[i-1], S.ES[i]-1 do local j = S.E[e]
      mv = mv + 1; m2 = m2 + 1
      if S.flag[j] == 2 then vs = vs + 1; h2 = h2 + 1
      elseif not S:live(j) then h2 = h2 + 1; if S.VL.newbie[j] then vs = vs + 1 else hd = hd + 1 end end end end
  perStep[#perStep+1] = h2 .. "/" .. m2 end
print(string.format("риск по кратчайшим путям: ходов из состояний пути %d, в проигрыш %d (%.1f %%): скрытый %d (%.1f %%), видимый/смыт %d",
  mv, hd + vs, 100 * (hd + vs) / mv, hd, 100 * hd / mv, vs))
print("по шагам (проигрышных/всех ходов из состояний шага): " .. table.concat(perStep, " "))
S:free()
