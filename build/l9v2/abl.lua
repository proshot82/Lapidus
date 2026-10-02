-- build/l9v2/abl.lua файл.lua — узость абляций g18 и роль гребёнки. Для каждого фильтра: решаем ли и за сколько,
-- доля рёбер базового графа, которые он запрещает, и сколько ходов кратчайших путей он режет. Отдельно — контроль-мутация
-- «у гребёнки один выход вверх» (решаем ли, за сколько, метрики). Только метрики.
local L = dofile("build/l9v2/lib.lua")
local R, V, SV = L.R, L.V, L.SV
local F = dofile("build/l9a/filt.lua")
local F2 = dofile("build/l9a/filt2.lua")
local path = arg[1]
local def = dofile(path)
local S = L.load(def)
local lvl = S.lvl
local sp, dw = S:onShortest(), S:distWin()
local N = {}
-- держит только один столб: свободная деталь не бывает в столбе/на гребне колонки x
local function noHoverAt(x0)
  return function(l, st, ns)
    if ns.dead then return true end
    local col, top = F.columns(l, ns)
    for q, p in ipairs(l.pieces) do local c = ns.pos[q]
      if p.movable and c ~= 0 and not ns.fixed[q] and (col[c] or top[c]) then local x = R.xy(l, c); if x == x0 then return false end end end
    return true
  end
end
N.noHover7, N.noHover8 = noHoverAt(7), noHoverAt(8)
-- резьба сильнее струи: деталь не закрепляется на выходе гребёнки, пока сеть мокрая
N.noScrewWet = function(l, st, ns)
  if ns.dead then return true end
  if not F.wet(l, st) then return true end
  for q, p in ipairs(l.pieces) do if p.movable and p.tag ~= "nip" and ns.fixed[q] and not st.fixed[q] then
    local x, y = R.xy(l, ns.pos[q]); if y == 6 and (x == 7 or x == 8) then return false end end end
  return true
end
-- тройник не бывает выше гребней (ряд 3) иначе как... — проверка «губа обязательна»: тройник никогда не в ряду 3
N.teeNotRow3 = function(l, st, ns)
  if ns.dead then return true end
  local q = F.find(l, "tee"); local c = ns.pos[q]
  if c ~= 0 then local _, y = R.xy(l, c); if y <= 3 then return false end end
  return true
end
-- Лапидус телом не поднимает деталь: запрещён переход, где свободная деталь поднялась вверх, а под ней в ns — тело Лапидуса
N.noBodyLift = function(l, st, ns)
  if ns.dead then return true end
  local body = {}
  for _, c in ipairs(ns.body) do body[c] = true end
  for q, p in ipairs(l.pieces) do local c, c2 = st.pos[q], ns.pos[q]
    if p.movable and c ~= 0 and c2 ~= 0 and not ns.fixed[q] then
      local _, y1 = R.xy(l, c); local _, y2 = R.xy(l, c2)
      if y2 < y1 and body[l.nb[c2][R.DOWN]] then return false end end end
  return true
end
local filters = {
  { "автор: фонтан не держит (noHover)", F.noHover },
  { "автор: не вдавить сверху (noPushDown)", F.noPushDown },
  { "автор: стопки нет (noStack)", F2.noStack },
  { "узк: деталь не поднимает другую (noLift)", F2.noLift },
  { "узк: из столба не сдвинуть вбок (noSideFromHold)", F2.noSideFromHold },
  { "узк: с гребня не сдвинуть вбок (noRideMove)", F2.noRideMove },
  { "узк: с гребня на гребень нельзя", F2.noCrestToCrest },
  { "узк: ближний столб не держит", N.noHover7 },
  { "узк: дальний столб не держит", N.noHover8 },
  { "узк: на мокрый выход не прикрутить", N.noScrewWet },
  { "узк: Лапидус телом не поднимает деталь", N.noBodyLift },
  { "проба: тройник не выше ряда 4", N.teeNotRow3 },
}
print("фильтр | решаем? | режет рёбер базового графа | режет ходов кратчайших путей")
for _, f in ipairs(filters) do
  local cut, tot, cutSp = 0, 0, 0
  for i = 1, S.n do if S.flag[i] == 0 then local st = S:st(i)
    for m = 1, 8 do local mm = R.MOVES[m]
      local ns = R.move(lvl, st, mm.which, mm.dir)
      if ns then tot = tot + 1
        if not f[2](lvl, st, ns) then cut = cut + 1
          if sp[i] and not ns.dead then local j = S.G.index[R.key(ns)]; if j and sp[j] and dw[j] == dw[i] - 1 then cutSp = cutSp + 1 end end
        end end end end end
  local G = SV.explore(lvl, 3000000, f[2])
  print(string.format("  %-48s %-14s %5.1f %%  %d", f[1], G.firstWin and ("решаем за " .. G.depth[G.firstWin]) or "нерешаем", 100 * cut / tot, cutSp))
  SV.freeGraph(G)
  io.stdout:flush()
end
S:free()
