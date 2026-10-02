-- py_c3_l4_r3_L6 (кв. 6 «Намертво», направление D «Он сам себе кран»). Решения здесь нет.

return {
  visibleLoss = dofile("build/l6c/d_crane/visP.lua"),
  id = 6, flat = 6, name = "Намертво", length = { 3, 6 }, pressure = 0, tile = "mustard",
  grid = {
    "#############",
    "#####.#.#####",
    "#####.#.#####",
    "#####.#.#####",
    "#...........#",
    "#######.#####",
    "#######..####",
    "#############",
    "#############",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 6, 2 }, ports = { down = "V" } },
    { kind = "source", at = { 9, 7 }, ports = { left = "N" } },
    { kind = "fitting", what = "elbow", tag = "C", at = { 8, 4 }, ports = { right = "V", up = "V" } },
    { kind = "fitting", what = "nipple", tag = "B", at = { 6, 4 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 3, 5 }, { 4, 5 }, { 5, 5 }, { 6, 5 }, { 7, 5 }, { 8, 5 } }, head = 6 },
  },
}
