-- Квартира 1, строгий поиск (шире): ядро то же; свободны весь верх и правая часть, старт — где угодно
-- наверху. Цель — ≤ 1 % наобум за 1000 ходов при коридоре §7.
return {
  id = 1, flat = 1, name = "Не той стороной", length = { 2, 4 }, pressure = 0,
  target = { moves = { 18, 30 }, states = 20000, dead = 25, fb = 1 },
  minStates = 0, searchCap = 20000, wallProb = 0.4, drainProb = 0.3, wallPenalty = 0,
  strict = { monkey = 1.0, shortest = 6 },
  grid = {
    "##########",
    "#????????#",
    "#?.#.????#",
    "#?.#.#???#",
    "##.#.#???#",
    "#......??#",
    "####~#???#",
  },
  objects = {
    { kind = "source", at = { 2, 6 }, ports = { right = "V" } },
    { kind = "fixture", what = "bath", at = { 7, 6 }, ports = { left = "N" } },
    { kind = "stub", tag = "hook", at = { 5, 3 }, ports = { down = "V" } },
  },
  lapidus = { area = { 2, 2, 9, 5 }, len = { 2, 4 } },
  ablations = { { name = "без крюка", remove = "hook" } },
}
