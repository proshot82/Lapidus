-- build/l10v/marks.lua файл.lua — разметки видимого проигрыша для o34: правила файла (W, T) по отдельности и вместе,
-- карман 3/4/5/6, знаток; проверочные разметки скептика:
--   Y «мойка отрезана»: тройник закреплён на стояке, а мойка сухая — колодец закрыт навсегда, в тоннель больше ничего
--      не попадёт (видно с одного взгляда: прибор замурован, сеть к нему не дошла);
--   K «конвейер предрешён»: незакреплённая деталь лежит в тоннеле одна у дальнего края, её левая резьба не подходит к мойке
--      (следующая упавшая деталь неизбежно дожмёт её к мойке — вывод по правилам напора в один шаг).
-- Каждое правило проверяется на «не помечает живых». Только метрики.
local L = dofile("build/l10v/lib.lua")
local S = L.load(arg[1])
local R, V = L.R, L.V
local lvl, def = S.lvl, S.def
local tags, sinkQ = {}, nil
for q, p in ipairs(lvl.pieces) do if p.tag then tags[p.tag] = q end; if p.what == "sink" then sinkQ = q end end
local base = L.SV.deepcopy(def); base.visibleLoss = nil
local function VLp(d, pk) V.POCKET = pk; local x = V.compute(lvl, S.G, d, S.good); V.POCKET = 4; return x end
local B = {}
for _, pk in ipairs({ 3, 4, 5, 6 }) do B[pk] = { base = VLp(base, pk), full = (pk == 4) and S.VL or VLp(def, pk) } end
local rules = {}
for k, f in pairs(def.visRules or {}) do rules[k] = function(s) return f(lvl, s) end end
local srcCell = R.idx(lvl, 6, 7)
rules.Y = function(s)
  local q = tags.tee
  if not (s.pos[q] == srcCell and s.fixed[q]) then return false end
  local w = R.water(lvl, s)
  return not w.wet[sinkQ]
end
rules.K = function(s)
  local c4, c5 = R.idx(lvl, 4, 7), R.idx(lvl, 5, 7)
  local at4, at5
  for q, p in ipairs(lvl.pieces) do if p.movable and s.pos[q] == c4 then at4 = q end; if p.movable and s.pos[q] == c5 then at5 = q end end
  if at5 and not at4 and not s.fixed[at5] then
    local pl = lvl.pieces[at5].ports[R.LEFT]
    return not (pl and R.match(pl, "V"))
  end
  return false
end
local marks, names = {}, {}
for k in pairs(rules) do names[#names+1] = k end
table.sort(names)
print("правило | помечает живых (должно быть 0) | скрытых по голой линейке (карман 4) | видимых по голой линейке | скрытых по файлу")
for _, nm in ipairs(names) do
  local m, lv, hd, vs, hf = 0, 0, 0, 0, 0
  local mk = {}
  for i = 1, S.n do if S.flag[i] ~= 2 then
    if rules[nm](S:st(i)) then mk[i] = true
      if S:live(i) then lv = lv + 1 elseif B[4].base.newbie[i] then vs = vs + 1 else hd = hd + 1 end
      if not S:live(i) and not S.VL.newbie[i] then hf = hf + 1 end end end end
  marks[nm] = mk
  print(string.format("  %-4s живых %d, скрытых(голая) %d, видимых(голая) %d, скрытых(файл) %d", nm, lv, hd, vs, hf))
end
local sp = S:onShortest()
local function combo(baseArr, list)
  local arr = {}
  for i = 1, S.n do if S.flag[i] ~= 2 then
    local v = baseArr[i] or false
    if not v then for _, nm in ipairs(list) do if marks[nm][i] and not S:live(i) then v = true break end end end
    arr[i] = v end end
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
  print(string.format("  %-22s %5.1f %%  обез %.3f  гл %2d  двери с любых кратчайших [%s]", lbl, m.hiddenPct, m.smart, m.maxDeep, doors(arr)))
end
print("разметка (карман 4) | скрытых | обезьяна | глубина | двери (шаг:число рёбер)")
line("голая линейка", B[4].base.newbie)
for _, nm in ipairs({ "T", "W" }) do line("линейка+" .. nm, combo(B[4].base.newbie, { nm })) end
line("файл (W+T)", S.VL.newbie)
line("файл+Y", combo(S.VL.newbie, { "Y" }))
line("файл+K", combo(S.VL.newbie, { "K" }))
line("файл+Y+K", combo(S.VL.newbie, { "Y", "K" }))
line("знаток", S.VL.expert)
print("карман 3/4/5/6 | голая линейка | файл | файл+Y+K")
for _, pk in ipairs({ 3, 4, 5, 6 }) do
  local a = V.measure(S.G, S.good, B[pk].base.newbie).hiddenPct
  local b = V.measure(S.G, S.good, B[pk].full.newbie).hiddenPct
  local c = V.measure(S.G, S.good, combo(B[pk].full.newbie, { "Y", "K" })).hiddenPct
  print(string.format("  карман %d: %5.1f %% | %5.1f %% | %5.1f %%", pk, a, b, c))
end
local c = S.VL.counts
print(string.format("причины видимого (файл): смыто %d, заморожено/карман %d, правило уровня %d", c.washed, c.frozen, c.levelRule))
