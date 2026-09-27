-- Квартира 5 «Лишний выход» — минимальная раскладка (24.09.2026, метод «теорема → поле не больше нужного»).
-- Ядро авторское: тройник лежит на полке, столкнуть его можно только вправо и только встав на заглушку;
-- он падает по столбу на стояк, его левый выход висит над сливом, заглушка ловится на резьбу только после
-- установки тройника. Правая часть закрыта: стояк и полотенцесушитель — не ступеньки.
-- Шахта 4 высотой ровно на клетку выше досягаемости (длина 2–4); выемка над сливом (5,5) — проход к финалу после того,
-- как заглушка закреплена. 15 ходов, один кратчайший путь; три абляции нерешаемы.
local function stepFilter(lvl, st, ns)
  -- абляция «ступенька запрещена»: нельзя столкнуть тройник с полки, стоя на незакреплённой заглушке
  local tq, pq
  for q, p in ipairs(lvl.pieces) do if p.what == "tee" then tq = q elseif p.what == "plug" then pq = q end end
  local start = lvl.pieces[tq].start
  if not (st.pos[tq] == start and ns.pos[tq] ~= start) then return true end
  local pc = st.pos[pq]
  if pc == 0 or st.fixed[pq] then return true end
  local above = lvl.nb[pc][1]
  for _, c in ipairs(st.body) do if c == above then return false end end
  return true
end
return {
  id = 5, flat = 5, name = "Лишний выход",
  length = { 2, 4 }, pressure = 0, tile = "blue",
  target = { moves = { 12, 40 }, states = 100000, dead = 35, fb = 1 },
  grid = {
    "#########",
    "#.....###",
    "#...#.###",
    "#...#...#",
    "#......##",
    "#......##",
    "####~####",
  },
  objects = {
    { kind = "source", at = { 7, 6 }, ports = { left = "N" } },
    { kind = "fixture", what = "dryer", at = { 8, 4 }, ports = { left = "N" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 5, 2 }, ports = { up = "V", right = "V", left = "V" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { 3, 6 }, ports = { right = "N" } },
    { kind = "lapidus", cells = { { 2, 4 }, { 2, 5 }, { 2, 6 } }, head = 1 },
  },
  ablations = {
    { name = "без заглушки", remove = "plug" },
    { name = "тройник заглушён заранее", remove = "plug",
      mutate = function(d) for _, o in ipairs(d.objects) do if o.tag == "tee" then o.ports.left = nil end end end },
    { name = "ступенька запрещена", filter = stepFilter },
  },
  texts = {
    request = "Полотенцесушитель холодный, носки мокрые. Пропажу второго носка прошу считать отдельной заявкой.",
    hints = {
      "Заглушка — единственная ступенька наверх. Сначала лестница, потом пробка.",
      "Ваш звонок очень важен для нас. Проверяем, не лишний ли у вас выход.",
      "Мастер выехал. Стремянку он с собой не возит.",
    },
  },
}
