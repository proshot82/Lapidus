-- BR: Лапидус — мост над сливом; крючья (колонка/стояк) меняют тип, когда на них встаёт деталь
return {
  length = { 3, 5 }, maxQ = 10,
  visibleLoss = function() return false end,
  grid = {
    "###########",
    "#?????????#",
    "#.........#",
    "##.##?##.##",
    "#.........#",
    "##~~~~~~~##",
  },
  objects = {
    { kind = "source", at = { 10, 5 }, ports = { left = "N" } },
    { kind = "fixture", what = "heater", at = { 2, 5 }, ports = { right = "V" } },
    { kind = "fitting", what = "nipple", tag = "pn", at = { 4, 3 }, ports = { left = "N", right = "N" } },
    { kind = "fitting", what = "coupling", tag = "pc", at = { 8, 3 }, ports = { left = "V", right = "V" } },
  },
  starts = {
    { cells = { { 5, 3 }, { 6, 3 }, { 7, 3 } }, head = 1 },
    { cells = { { 5, 3 }, { 6, 3 }, { 7, 3 } }, head = 3 },
  },
}
