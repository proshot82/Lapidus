-- кандидат c01 (рабочее имя a0); метрики — progress.txt
return {
  id = 10, flat = 10, name = "c01", length = { 2, 6 }, pressure = 0, tile = "mustard",
  grid = {
    "################",
    "#..............#",
    "#..............#",
    "#..............#",
    "#..............#",
    "#..............#",
    "#..............#",
    "########.......#",
    "#..............#",
    "########~~######",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 2, 9 }, ports = { right = "V" } },
    { kind = "source", at = { 11, 9 }, ports = { left = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 13, 7 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 12, 7 }, ports = { left = "N", right = "N" } },
    { kind = "lapidus", cells = { { 12, 9 }, { 13, 9 }, { 14, 9 } }, head = 1 },
  },
}
