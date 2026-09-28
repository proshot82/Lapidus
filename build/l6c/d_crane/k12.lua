-- k12 (кв. 6 «Намертво», направление D «Он сам себе кран»). Решения здесь нет.

return {
  visibleLoss = dofile("build/l6c/d_crane/visK.lua"),
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "##########",
    "###.######",
    "###.######",
    "###.######",
    "###.######",
    "###....###",
    "##..##.###",
    "#........#",
    "##########",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 4, 2 }, ports = { down = "V" } },
    { kind = "fitting", what = "elbow", tag = "C", at = { 6, 6 }, ports = { left = "V", up = "V" } },
    { kind = "source", at = { 3, 7 }, ports = { right = "N" } },
    { kind = "fitting", what = "nipple", tag = "B", at = { 4, 7 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 7, 8 }, { 6, 8 }, { 5, 8 }, { 4, 8 }, { 3, 8 } }, head = 5 },
  },
}
