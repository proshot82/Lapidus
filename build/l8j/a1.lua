-- a1: проба механики «поймал на ноги — поднял» (минимальная раскладка, не кандидат).
return {
  id = 8, flat = 8, name = "a1", length = { 2, 4 }, pressure = 0, tile = "mint",
  grid = {
    "##########",
    "##########",
    "####..####",
    "#####.####",
    "#####.####",
    "#####.####",
    "#........#",
    "######.###",
    "##########",
  },
  objects = {
    { kind = "source", at = { 6, 8 }, ports = { up = "N" } },
    { kind = "fixture", what = "sink", at = { 5, 3 }, ports = { right = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 6, 6 }, ports = { left = "V", down = "V" } },
    { kind = "porcelain", tag = "soap", at = { 6, 7 } },
    { kind = "lapidus", cells = { { 2, 7 }, { 3, 7 } }, head = 1 },
  },
  ablations = { { name = "без угольника", remove = "elb" }, { name = "без мыла", remove = "soap" } },
}
