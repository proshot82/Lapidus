-- kq5s0 (кв. 6 «Намертво», направление D «Он сам себе кран»). Решения здесь нет.

return {
  visibleLoss = dofile("build/l6c/d_crane/visP.lua"),
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "#########",
    "#####.###",
    "###.#.###",
    "###.#.###",
    "###.#.###",
    "##......#",
    "###.#.#.#",
    "##......#",
    "#########",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 4, 3 }, ports = { down = "V" } },
    { kind = "fitting", what = "nipple", tag = "B", at = { 4, 5 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "elbow", tag = "C", at = { 6, 5 }, ports = { left = "V", down = "V" } },
    { kind = "source", at = { 6, 7 }, ports = { up = "N" } },
    { kind = "lapidus", cells = { { 4, 8 }, { 4, 7 }, { 4, 6 }, { 5, 6 }, { 6, 6 } }, head = 5 },
  },
}
