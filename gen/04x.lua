-- Квартира 4, строгий поиск: ядро (зазор, окно, муфта, ниппель, труба, машинка) зафиксировано;
-- мутатор закрывает лишние маршруты: кратчайших вариантов ≤ 4, наобум ≤ 1 %.
return {
  id = 4, flat = 4, name = "Резьба", length = { 2, 4 }, pressure = 0,
  target = { moves = { 30, 50 }, states = 300000, dead = 40, fb = 2 },
  minStates = 0, searchCap = 150000, wallProb = 0.3, drainProb = 0.3, wallPenalty = 0,
  strict = { monkey = 1.0, shortest = 4 },
  grid = {
    "###########",
    "#?????????#",
    "#?..#?????#",
    "#?#.......#",
    "#?...###.##",
    "####.#????#",
    "####.#????#",
    "######??###",
  },
  objects = {
    { kind = "source", at = { 5, 7 }, ports = { up = "N" } },
    { kind = "pipe", at = { 5, 4 }, ports = { down = "V", right = "N" } },
    { kind = "fitting", tag = "part", what = "coupling", at = { 3, 5 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", tag = "part", what = "nipple", at = { 3, 3 }, ports = { up = "N", down = "N" } },
    { kind = "fixture", what = "washer", at = { 10, 4 }, ports = { left = "V" } },
  },
  lapidus = { area = { 7, 6, 10, 7 }, len = { 2, 3 } },
  ablations = { { name = "без деталей", remove = "part" } },
}
