-- pt_d3_c3_l1_Hleft (кв. 6 «Намертво», направление D «Он сам себе кран»). Решения здесь нет.

return {
  visibleLoss = dofile("build/l6c/d_crane/visP.lua"),
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "###########",
    "###########",
    "##.##.#####",
    "##.##.#####",
    "##.##.#####",
    "#.........#",
    "#####.#####",
    "#####..####",
    "###########",
    "###########",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 3, 3 }, ports = { down = "V" } },
    { kind = "source", at = { 7, 8 }, ports = { left = "N" } },
    { kind = "fitting", what = "elbow", tag = "C", at = { 6, 5 }, ports = { right = "V", up = "V" } },
    { kind = "fitting", what = "nipple", tag = "B", at = { 3, 5 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 6, 6 }, { 5, 6 }, { 4, 6 }, { 3, 6 }, { 2, 6 } }, head = 5 },
  },
}
