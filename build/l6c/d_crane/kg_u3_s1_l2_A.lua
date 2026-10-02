-- kg_u3_s1_l2_A (кв. 6 «Намертво», направление D «Он сам себе кран»). Решения здесь нет.

return {
  visibleLoss = dofile("build/l6c/d_crane/visK.lua"),
  shelf = 6,
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "##########",
    "####.#####",
    "####.#####",
    "####.#####",
    "####.#####",
    "####.....#",
    "####.#.#.#",
    "##.......#",
    "##########",
    "##########",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 5, 2 }, ports = { down = "V" } },
    { kind = "source", at = { 7, 7 }, ports = { up = "N" } },
    { kind = "fitting", what = "elbow", tag = "C", at = { 8, 6 }, ports = { left = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "B", at = { 5, 5 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 7, 8 }, { 6, 8 }, { 5, 8 }, { 5, 7 }, { 5, 6 } }, head = 5 },
  },
}
