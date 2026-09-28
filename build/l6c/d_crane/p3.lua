-- p3 (кв. 6 «Намертво», направление D «Он сам себе кран»). Решения здесь нет.

return {
  visibleLoss = dofile("build/l6c/d_crane/visP.lua"),
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "##########",
    "##########",
    "###.######",
    "###.######",
    "###.#.####",
    "#........#",
    "#####.####",
    "#####..###",
    "##########",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 4, 3 }, ports = { down = "V" } },
    { kind = "fitting", what = "nipple", tag = "B", at = { 4, 5 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "elbow", tag = "C", at = { 6, 5 }, ports = { right = "V", up = "V" } },
    { kind = "source", at = { 7, 8 }, ports = { left = "N" } },
    { kind = "lapidus", cells = { { 8, 6 }, { 7, 6 }, { 6, 6 }, { 5, 6 }, { 4, 6 } }, head = 5 },
  },
}
