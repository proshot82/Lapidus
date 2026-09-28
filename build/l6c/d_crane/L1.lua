-- L1 (кв. 6 «Намертво», направление D «Он сам себе кран»). Решения здесь нет.

return {
  visibleLoss = dofile("build/l6c/d_crane/vis0.lua"),
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "##########",
    "#####.####",
    "#####.####",
    "#####.####",
    "#####.#.##",
    "#........#",
    "#######.##",
    "##########",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 6, 2 }, ports = { down = "V" } },
    { kind = "fitting", what = "nipple", tag = "B", at = { 6, 5 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "elbow", tag = "C", at = { 8, 5 }, ports = { down = "V", left = "V" } },
    { kind = "source", at = { 8, 7 }, ports = { up = "N" } },
    { kind = "lapidus", cells = { { 5, 6 }, { 6, 6 }, { 7, 6 }, { 8, 6 }, { 9, 6 } }, head = 5 },
  },
}
