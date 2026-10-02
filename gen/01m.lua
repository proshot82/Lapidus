-- Уровень 1, зеркальный скелет: спуск ногами вперёд по шахте у стояка, поворот на крюке
-- над сливом; справа — место под комнату-ловушку, в которую можно только упасть.
return {
  id = 1, flat = 1, name = "Не той стороной",
  length = { 2, 4 }, pressure = 0,
  target = { moves = { 18, 30 }, states = 20000, dead = 25, fb = 1 },
  minStates = 0, searchCap = 20000, wallProb = 0.45, drainProb = 0.3, wallPenalty = 0,
  grid = {
    "##########",
    "#????????#",
    "##.#.????#",
    "##.#.#???#",
    "##.#.#???#",
    "#......??#",
    "####~##??#",
  },
  objects = {
    { kind = "source", at = { 2, 6 }, ports = { right = "V" } },
    { kind = "fixture", what = "sink", at = { 7, 6 }, ports = { left = "N" } },
    { kind = "stub", tag = "hook", at = { 5, 3 }, ports = { down = "V" } },
  },
  lapidus = { area = { 2, 2, 9, 5 }, len = { 2, 3 } },
  ablations = { { name = "без крюка", remove = "hook" } },
}
