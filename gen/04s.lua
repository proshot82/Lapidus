-- Квартира 4 «Резьба»: зазор в две клетки между стояком (Н вверх) и трубой (В вниз), вход — окно в одну
-- клетку. Муфта (В/В) должна упасть первой и прикрутиться к стояку, ниппель (Н/Н) — второй. Собранная
-- заранее пара (две клетки ростом) в окно не пролезает; обратный порядок — ниппель ложится без резьбы.
return {
  id = 4, flat = 4, name = "Резьба", length = { 2, 4 }, pressure = 0,
  target = { moves = { 30, 50 }, states = 300000, dead = 40, fb = 2 },
  minStates = 0, searchCap = 120000, wallProb = 0.35, drainProb = 0.25, wallPenalty = 0,
  grid = {
    "###########",
    "#?????????#",
    "#?????????#",
    "#??#..????#",
    "#??..#????#",
    "#??#.#????#",
    "#??#.#????#",
    "#?????????#",
  },
  objects = {
    { kind = "source", at = { 5, 7 }, ports = { up = "N" } },
    { kind = "pipe", at = { 5, 4 }, ports = { down = "V", right = "N" } },
    { kind = "fitting", tag = "part", what = "coupling", area = { 2, 2, 4, 5 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", tag = "part", what = "nipple", area = { 2, 2, 4, 5 }, ports = { up = "N", down = "N" } },
    { kind = "fixture", what = "washer", area = { 7, 2, 10, 7 }, portsOptions = { { left = "V" }, { up = "V" }, { down = "V" } } },
  },
  near = { 2, 5, 5 },
  lapidus = { area = { 6, 2, 10, 7 }, len = { 2, 3 } },
  ablations = { { name = "без деталей", remove = "part" } },
}
