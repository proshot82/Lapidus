-- t3 (кв. 6 «Намертво», направление D «Он сам себе кран»). Решения здесь нет.

return {
  visibleLoss = dofile("build/l6c/d_crane/visB.lua"),
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "#######",
    "##.####",
    "##.####",
    "##.####",
    "##..###",
    "##..###",
    "##..###",
    "##...##",
    "#######",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 3, 2 }, ports = { down = "V" } },
    { kind = "fitting", what = "nipple", tag = "B", at = { 3, 5 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "elbow", tag = "C", at = { 4, 5 }, ports = { right = "V", up = "V" } },
    { kind = "source", at = { 5, 8 }, ports = { left = "N" } },
    { kind = "lapidus", cells = { { 3, 6 }, { 4, 6 }, { 4, 7 }, { 4, 8 }, { 3, 8 } }, head = 5 },
  },
}
