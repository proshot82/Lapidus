-- kg_u3_s2_l0_A (кв. 6 «Намертво», направление D «Он сам себе кран»). Решения здесь нет.

return {
  visibleLoss = dofile("build/l6c/d_crane/visK.lua"),
  shelf = 6,
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "#########",
    "##.######",
    "##.######",
    "##.######",
    "##.######",
    "##......#",
    "##.##.#.#",
    "##......#",
    "#########",
    "#########",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 3, 2 }, ports = { down = "V" } },
    { kind = "source", at = { 6, 7 }, ports = { up = "N" } },
    { kind = "fitting", what = "elbow", tag = "C", at = { 7, 6 }, ports = { left = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "B", at = { 3, 5 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 5, 8 }, { 4, 8 }, { 3, 8 }, { 3, 7 }, { 3, 6 } }, head = 5 },
  },
}
