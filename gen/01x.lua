-- Квартира 1, строгий поиск: ядро (спуск ногами вперёд, поворот на крюке над сливом) зафиксировано;
-- мутатор строит ловушки так, чтобы наобум проходилось ≤ 1 % за 1000 ходов, а кратчайших было ≤ 4.
return {
  id = 1, flat = 1, name = "Не той стороной", length = { 2, 4 }, pressure = 0,
  target = { moves = { 18, 30 }, states = 20000, dead = 25, fb = 1 },
  minStates = 0, searchCap = 20000, wallProb = 0.45, drainProb = 0.35, wallPenalty = 0,
  strict = { monkey = 1.0, shortest = 4 },
  grid = {
    "##########",
    "#????????#",
    "##.#.????#",
    "##.#.#???#",
    "##.#.#???#",
    "#......??#",
    "####~#???#",
  },
  objects = {
    { kind = "source", at = { 2, 6 }, ports = { right = "V" } },
    { kind = "fixture", what = "bath", at = { 7, 6 }, ports = { left = "N" } },
    { kind = "stub", tag = "hook", at = { 5, 3 }, ports = { down = "V" } },
  },
  lapidus = { area = { 2, 2, 9, 5 }, len = { 2, 3 } },
  ablations = { { name = "без крюка", remove = "hook" } },
}
