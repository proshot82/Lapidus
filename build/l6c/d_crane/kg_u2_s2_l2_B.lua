-- kg_u2_s2_l2_B (кв. 6 «Намертво», направление D «Он сам себе кран»). Решения здесь нет.

return {
  visibleLoss = dofile("build/l6c/d_crane/visK.lua"),
  shelf = 5,
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "###########",
    "####.######",
    "####.######",
    "####.######",
    "####......#",
    "####.##.#.#",
    "##........#",
    "###########",
    "###########",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 5, 2 }, ports = { down = "V" } },
    { kind = "source", at = { 8, 6 }, ports = { up = "N" } },
    { kind = "fitting", what = "elbow", tag = "C", at = { 9, 5 }, ports = { left = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "B", at = { 5, 4 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 5, 5 }, { 5, 6 }, { 5, 7 }, { 6, 7 }, { 7, 7 } }, head = 5 },
  },
}
