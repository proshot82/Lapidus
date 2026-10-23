return {
  grid = {
    "##############",
    "#######......#",
    "#######......#",
    "#######......#",
    "#............#",
    "#######~~#####",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 2, 5 }, ports = { right = "V" } },
    { kind = "source", at = { 10, 5 }, ports = { left = "N" } },
  },
  minMoves = 18,
}
