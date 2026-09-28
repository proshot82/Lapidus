-- c1 (кв. 6 «Намертво», направление D «Он сам себе кран»). Решения здесь нет.

return {
  visibleLoss = dofile("build/l6c/d_crane/vis0.lua"),
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "#######",
    "#....##",
    "#....##",
    "##.#.##",
    "##..###",
    "##..###",
    "##..###",
    "#######",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 2, 2 }, ports = { right = "V" } },
    { kind = "source", at = { 2, 3 }, ports = { right = "N" } },
    { kind = "fitting", what = "nipple", tag = "B", at = { 3, 4 }, ports = { left = "N", right = "N" } },
    { kind = "fitting", what = "coupling", tag = "C", at = { 3, 6 }, ports = { left = "V", right = "V" } },
    { kind = "lapidus", cells = { { 3, 5 }, { 4, 5 }, { 4, 6 }, { 4, 7 }, { 3, 7 } }, head = 5 },
  },
}
