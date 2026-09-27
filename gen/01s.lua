-- Уровень 1, авторский скелет: ядро (поворот на крюке над сливом) зафиксировано,
-- мутатор достраивает ловушки в свободных зонах и выбирает старт.
return {
  id = 1, flat = 1, name = "Не той стороной",
  length = { 2, 4 }, pressure = 0,
  target = { moves = { 18, 30 }, states = 20000, dead = 25, fb = 1 },
  minStates = 0, searchCap = 20000, wallProb = 0.65, drainProb = 0.3, wallPenalty = 0,
  grid = {
    "##########",
    "#????????#",
    "#????....#",
    "#??.?.??.#",
    "#??.?.??.#",
    "#........#",
    "#??~?????#",
  },
  objects = {
    { kind = "fixture", what = "sink", at = { 2, 6 }, ports = { right = "N" } },
    { kind = "source", at = { 7, 6 }, ports = { left = "V" } },
    { kind = "stub", tag = "hook", at = { 4, 4 }, ports = { down = "V" } },
  },
  lapidus = { area = { 2, 2, 9, 6 }, len = { 2, 3 } },
  ablations = { { name = "без крюка", remove = "hook" } },
}
