-- build/l9v2/marks.lua файл.lua — разметки видимого проигрыша для g18: правила файла (def.visRules) по отдельности,
-- карман 3/4/5/6 с правилами и без, и проверочные разметки скептика:
--   Y «гнездо тройника»: тройник закреплён не в единственной клетке, где сходятся три резьбы (разрыв линии унитаза);
--      единственная трёхрезьбовая деталь потрачена — разрыв закрыть нечем (вывод в один шаг, без финальной сборки);
--   D «карточка: сухая хватает»: деталь (кроме ниппеля) закреплена на сухой сети не там, где в финале (мерка знатока карточки).
-- Каждое правило проверяется на «не помечает живых». Только метрики.
local L = dofile("build/l9v2/lib.lua")
local S = L.load(arg[1])
local R, V = L.R, L.V
local lvl = S.lvl
local def = S.def
local tags = {}
for q, p in ipairs(lvl.pieces) do if p.tag then tags[p.tag] = q end end
local win = S.VL.win
local base = L.SV.deepcopy(def); base.visibleLoss = nil
local function VLp(d, pk) V.POCKET = pk; local x = V.compute(lvl, S.G, d, S.good); V.POCKET = 4; return x end
local B = {}
for _, pk in ipairs({ 3, 4, 5, 6 }) do B[pk] = { base = VLp(base, pk), full = (pk == 4) and S.VL or VLp(def, pk) } end
local rules = {}
for k, f in pairs(def.visRules or {}) do rules[k] = function(s) return f(lvl, s) end end
local sock = R.idx(lvl, 10, 7)
rules.Y = function(s) local q = tags.tee; return s.pos[q] ~= 0 and s.fixed[q] and s.pos[q] ~= sock end
rules.D = function(s)
  if S:wet(s) then return false end
  for q, p in ipairs(lvl.pieces) do if p.movable and p.tag ~= "nip" and s.pos[q] ~= 0 and s.fixed[q]
    and not (win.fixed[q] and win.pos[q] == s.pos[q]) then return true end end
  return false
end
local marks, names = {}, {}
for k in pairs(rules) do names[#names+1] = k end
table.sort(names)
print("правило | помечает живых (должно быть 0) | скрытых по голой линейке (карман 4) | видимых по голой линейке")
for _, nm in ipairs(names) do
  local m, lv, hd, vs = {}, 0, 0, 0
  for i = 1, S.n do if S.flag[i] ~= 2 then
    if rules[nm](S:st(i)) then m[i] = true
      if S:live(i) then lv = lv + 1 elseif B[4].base.newbie[i] then vs = vs + 1 else hd = hd + 1 end end end end
  marks[nm] = m
  print(string.format("  %-6s живых %d, скрытых %d, видимых %d", nm, lv, hd, vs))
end
local sp = S:onShortest()
local function combo(baseArr, list)
  local arr = {}
  for i = 1, S.n do if S.flag[i] ~= 2 then
    local v = baseArr[i] or false
    if not v then for _, nm in ipairs(list) do if marks[nm][i] and not S:live(i) then v = true break end end end
    arr[i] = v
  end end
  return arr
end
local function doors(arr)
  local ph = {}
  for i = 1, S.n do if sp[i] and S.flag[i] == 0 then
    for e = S.ES[i-1], S.ES[i]-1 do local j = S.E[e]
      if S:hid(j, arr) then ph[S.G.depth[i]] = (ph[S.G.depth[i]] or 0) + 1 end end end end
  local t = {}
  for d = 0, S:opt() - 1 do if ph[d] then t[#t+1] = d .. ":" .. ph[d] end end
  return table.concat(t, " ")
end
local function line(lbl, arr)
  local m = V.measure(S.G, S.good, arr)
  print(string.format("  %-26s %5.1f %%  обез %.3f  гл %2d  двери с любых кратчайших [%s]", lbl, m.hiddenPct, m.smart, m.maxDeep, doors(arr)))
end
local fileR = {}
for k in pairs(def.visRules or {}) do fileR[#fileR+1] = k end
table.sort(fileR)
print("разметка (карман 4) | скрытых | обезьяна | глубина | двери")
line("голая линейка", B[4].base.newbie)
for _, nm in ipairs(fileR) do line("линейка+" .. nm, combo(B[4].base.newbie, { nm })) end
line("файл (все правила)", S.VL.newbie)
line("файл+Y", combo(S.VL.newbie, { "Y" }))
line("файл+D", combo(S.VL.newbie, { "D" }))
line("файл+Y+D", combo(S.VL.newbie, { "Y", "D" }))
line("знаток", S.VL.expert)
print("карман 3/4/5/6 | голая линейка | файл | файл+Y")
for _, pk in ipairs({ 3, 4, 5, 6 }) do
  local a = V.measure(S.G, S.good, B[pk].base.newbie).hiddenPct
  local b = V.measure(S.G, S.good, B[pk].full.newbie).hiddenPct
  local c = V.measure(S.G, S.good, combo(B[pk].full.newbie, { "Y" })).hiddenPct
  print(string.format("  карман %d: %5.1f %% | %5.1f %% | %5.1f %%", pk, a, b, c))
end
-- что даёт каждое правило файла сверх остальных (уникальный вклад)
print("уникальный вклад правил файла (скрытых, которые помечает только оно, сверх голой линейки и прочих правил)")
for _, nm in ipairs(fileR) do
  local u = 0
  for i = 1, S.n do if S.flag[i] ~= 2 and marks[nm][i] and not S:live(i) and not B[4].base.newbie[i] then
    local other = false
    for _, o in ipairs(fileR) do if o ~= nm and marks[o][i] then other = true break end end
    if not other then u = u + 1 end end end
  print(string.format("  %-6s %d", nm, u))
end
S:free()
