-- q1 (кв. 6 «Намертво», направление D «Он сам себе кран»). Решения здесь нет.

return {
  visibleLoss = dofile("build/l6c/d_crane/visQ.lua"),
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "#########",
    "###.#####",
    "###.#####",
    "###.#####",
    "#.......#",
    "###.###.#",
    "##......#",
    "#########",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 4, 2 }, ports = { down = "V" } },
    { kind = "fitting", what = "nipple", tag = "B", at = { 4, 4 }, ports = { up = "N", down = "N" } },
    { kind = "source", at = { 3, 7 }, ports = { right = "N" } },
    { kind = "fitting", what = "elbow", tag = "C", at = { 6, 7 }, ports = { left = "V", up = "V" } },
    { kind = "lapidus", cells = { { 2, 5 }, { 3, 5 }, { 4, 5 }, { 5, 5 }, { 6, 5 } }, head = 5 },
  },
}
