-- x3 (кв. 6 «Намертво», направление D «Он сам себе кран»). Решения здесь нет.

return {
  visibleLoss = dofile("build/l6c/d_crane/vis0.lua"),
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "#########",
    "####.####",
    "####.####",
    "####.####",
    "####.####",
    "##.#.####",
    "#.......#",
    "##.######",
    "#########",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 5, 2 }, ports = { down = "V" } },
    { kind = "fitting", what = "elbow", tag = "C", at = { 3, 6 }, ports = { down = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "B", at = { 5, 6 }, ports = { up = "N", down = "N" } },
    { kind = "source", at = { 3, 8 }, ports = { up = "N" } },
    { kind = "lapidus", cells = { { 3, 7 }, { 4, 7 }, { 5, 7 }, { 6, 7 }, { 7, 7 } }, head = 5 },
  },
}
