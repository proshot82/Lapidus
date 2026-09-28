-- dd5 (кв. 6 «Намертво», направление D «Он сам себе кран»). Решения здесь нет.

return {
  visibleLoss = dofile("build/l6c/d_crane/visP.lua"),
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "##########",
    "###.#.####",
    "#........#",
    "###.#.####",
    "###.#.####",
    "###.#.####",
    "##########",
  },
  objects = {
    { kind = "fitting", what = "nipple", tag = "B", at = { 4, 2 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "coupling", tag = "C", at = { 6, 2 }, ports = { up = "V", down = "V" } },
    { kind = "fixture", what = "heater", at = { 4, 6 }, ports = { up = "V" } },
    { kind = "source", at = { 6, 6 }, ports = { up = "N" } },
    { kind = "lapidus", cells = { { 3, 3 }, { 4, 3 }, { 5, 3 }, { 6, 3 }, { 7, 3 } }, head = 5 },
  },
}
