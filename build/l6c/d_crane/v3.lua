-- v3 (кв. 6 «Намертво», направление D «Он сам себе кран»). Решения здесь нет.

return {
  visibleLoss = dofile("build/l6c/d_crane/vis0.lua"),
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "########",
    "#####.##",
    "#####.##",
    "#####.##",
    "#.....##",
    "##.##.##",
    "#......#",
    "########",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 6, 2 }, ports = { down = "V" } },
    { kind = "source", at = { 2, 5 }, ports = { right = "N" } },
    { kind = "fitting", what = "coupling", tag = "C", at = { 3, 6 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "B", at = { 6, 6 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 6, 7 }, { 5, 7 }, { 4, 7 }, { 3, 7 }, { 2, 7 } }, head = 5 },
  },
}
