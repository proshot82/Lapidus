-- p4 (кв. 6 «Намертво», направление D «Он сам себе кран»). Решения здесь нет.

return {
  visibleLoss = dofile("build/l6c/d_crane/vis0.lua"),
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "#######",
    "##.#.##",
    "##.#.##",
    "##.#.##",
    "##...##",
    "#.....#",
    "#######",
  },
  objects = {
    { kind = "source", at = { 3, 2 }, ports = { down = "N" } },
    { kind = "fixture", what = "heater", at = { 5, 2 }, ports = { down = "V" } },
    { kind = "fitting", what = "coupling", tag = "C", at = { 3, 5 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "B", at = { 5, 5 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 6, 6 }, { 5, 6 }, { 4, 6 }, { 3, 6 } }, head = 4 },
  },
}
