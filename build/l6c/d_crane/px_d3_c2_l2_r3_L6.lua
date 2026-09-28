-- px_d3_c2_l2_r3_L6 (кв. 6 «Намертво», направление D «Он сам себе кран»). Решения здесь нет.

return {
  visibleLoss = dofile("build/l6c/d_crane/visP.lua"),
  id = 6, flat = 6, name = "Намертво", length = { 3, 6 }, pressure = 0, tile = "mustard",
  grid = {
    "############",
    "###.########",
    "###.##.#####",
    "###.##.#####",
    "#..........#",
    "######.#####",
    "######..####",
    "############",
    "############",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 4, 2 }, ports = { down = "V" } },
    { kind = "source", at = { 8, 7 }, ports = { left = "N" } },
    { kind = "fitting", what = "elbow", tag = "C", at = { 7, 4 }, ports = { right = "V", up = "V" } },
    { kind = "fitting", what = "nipple", tag = "B", at = { 4, 4 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 2, 5 }, { 3, 5 }, { 4, 5 }, { 5, 5 }, { 6, 5 }, { 7, 5 } }, head = 6 },
  },
}
