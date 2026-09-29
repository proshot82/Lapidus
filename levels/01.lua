-- Квартира 1 «Не той стороной» (пересобрана 24.09.2026 по методу «теорема → минимальная раскладка»).
-- Теорема: крюк — не цель, а точка опоры. Ванна висит прямо над стояком, оба порта смотрят влево: в финале Лапидус
-- свёрнут буквой U, ноги выше головы. Перевернуться так можно, только повиснув на глухом отводе.
-- Поиск: gen/01z.lua (60 тыс. кандидатов); абляции: без крюка и «крюк без крепления» (висеть запрещено) — нерешаем.
local function noHook(lvl, st, ns)
  local R = require("core.rules")
  local piece = R.occupancy(ns)
  for _, which in ipairs({ "head", "heel" }) do
    local q = R.endScrew(lvl, ns, piece, which)
    if q and lvl.pieces[q].kind == "stub" then return false end
  end
  return true
end
return {
  id = 1, flat = 1, name = "Не той стороной",
  length = { 2, 4 }, pressure = 0, tile = "mint",
  target = { moves = { 15, 40 }, states = 20000, dead = 25, fb = 1 },
  grid = {
    "#########",
    "#....#..#",
    "#.#..#..#",
    "#.#.....#",
    "##......#",
    "#.......#",
    "##~~~#~~#",
  },
  objects = {
    { kind = "source", at = { 8, 5 }, ports = { left = "N" } },
    { kind = "fixture", what = "bath", at = { 8, 4 }, ports = { left = "V" } },
    { kind = "stub", tag = "hook", at = { 3, 5 }, ports = { right = "N" } },
    { kind = "lapidus", cells = { { 2, 3 }, { 2, 2 } }, head = 2 },
  },
  ablations = {
    { name = "без крюка", remove = "hook" },
    { name = "крюк без крепления", filter = noHook },
  },
  texts = {
    request = "Ванна есть. Воды нет. Прошу наоборот.",
    hints = {
      "Развернуться можно, только повиснув на чужой резьбе. Прикрутите сначала «не тот» конец.",
      "Ваш звонок очень важен для нас. Проверяем, есть ли у вас выход.",
      "Мастер выехал. Смотрите внимательно: второй раз он не приедет.",
    },
  },
}
