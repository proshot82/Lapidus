-- Квартира 10 «За собой» — финал (03.10.2026, build/p6/fin; заменил «Намертво», архив — build/l10j/installed_namertvo_level10.lua).
-- Проверки: слепой скептик — PASS по воротам 03.10, слепой игрок — решил по плану, оба открытия найдены (build/p6/finv).
-- Замысел и решение здесь не пишутся.

-- Видимый проигрыш сверх общей линейки (tools/vislib.lua): все детали закреплены, а Лапидус целиком вне коридора
-- к колонке (ряд 6, x ≤ 9) — вход заткнут. Сужено по совету скептика: без этого условия помечались живые состояния.
local function allFixed(lvl, st)
  for q, p in ipairs(lvl.pieces) do if p.movable and not st.fixed[q] then return false end end
  for _, b in ipairs(st.body) do
    local x, y = (b - 1) % lvl.W + 1, math.floor((b - 1) / lvl.W) + 1
    if y == 6 and x <= 9 then return false end
  end
  return true
end

local function q(lvl, tag) for i, p in ipairs(lvl.pieces) do if p.tag == tag then return i end end end

-- Абляции роли (фильтры ходов)
-- «Только парой» — проверка ложного плана (собрать пару), а не абляция роли: запрещено состояние, где одна деталь уже закреплена, а другая ещё нет.
local function onlyPair(lvl, st, ns)
  local c, n = q(lvl, "cpl"), q(lvl, "nip")
  return not (ns.pos[c] ~= 0 and ns.pos[n] ~= 0 and ns.fixed[c] ~= ns.fixed[n])
end
-- «Не спускать на себе»: запрещено состояние, где незакреплённый ниппель лежит на Лапидусе в столбце над ближней
-- клеткой слива (x = 8).
local function noRide(lvl, st, ns)
  local n = q(lvl, "nip")
  local c = ns.pos[n]
  if c == 0 or ns.fixed[n] then return true end
  if (c - 1) % lvl.W + 1 ~= 8 then return true end
  local below = lvl.nb[c][3]
  for _, b in ipairs(ns.body) do if b == below then return false end end
  return true
end
-- «Без передачи»: запрещено состояние, где ниппель лежит на незакреплённой муфте.
local function noRelay(lvl, st, ns)
  local c, n = q(lvl, "cpl"), q(lvl, "nip")
  local a, b = ns.pos[n], ns.pos[c]
  if a == 0 or b == 0 or ns.fixed[c] then return true end
  return lvl.nb[a][3] ~= b
end

return {
  visibleLoss = allFixed,
  id = 10, flat = 10, name = "За собой",
  length = { 2, 6 }, pressure = 0, tile = "mustard",
  target = { moves = { 25, 45 }, states = 1000000, dead = 50, fb = 3 },
  grid = {
    "##############",
    "########....##",
    "#######......#",
    "#######.#.#..#",
    "#######.....##",
    "#............#",
    "#######~~#####",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 2, 6 }, ports = { right = "V" } },
    { kind = "source", at = { 10, 6 }, ports = { left = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 12, 5 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 11, 3 }, ports = { left = "N", right = "N" } },
    { kind = "lapidus", cells = { { 11, 6 }, { 12, 6 }, { 13, 6 } }, head = 1 },
  },
  ablations = {
    { name = "без муфты", remove = "cpl" },
    { name = "без ниппеля", remove = "nip" },
    { name = "только парой", filter = onlyPair },
    { name = "ниппель не спускается на Лапидусе", filter = noRide },
    { name = "ниппель не лежит на муфте", filter = noRelay },
  },
  texts = {
    request = "Колонка в нише за стенкой. Прошлый мастер собрал всё как по учебнику — и до утра стучал нам из трубы.",
    card = nil,
    hints = {
      "В шахту двоим не пролезть: кто-то пойдёт первым.",
      "Ваш звонок очень важен для нас. Пока ждёте, решите, каким концом вы полезете в трубу.",
      "Мастер выехал. Кепку он не снимает даже в шахте — так в ней и спускается.",
    },
  },
}
