-- u2 (кв. 6 «Намертво», направление D «Он сам себе кран»). Решения здесь нет.

return {
  visibleLoss = dofile("build/l6c/d_crane/vis0.lua"),
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "#########",
    "####.####",
    "#..#.##.#",
    "##.#.##.#",
    "#.......#",
    "#########",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 5, 2 }, ports = { down = "V" } },
    { kind = "source", at = { 2, 3 }, ports = { right = "N" } },
    { kind = "fitting", what = "elbow", tag = "C", at = { 3, 4 }, ports = { left = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "B", at = { 5, 4 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 3, 5 }, { 4, 5 }, { 5, 5 }, { 6, 5 }, { 7, 5 } }, head = 5 },
  },
}
