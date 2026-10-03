return {
  grid = {
    "##############",
    "##############",
    "#######......#",
    "#######.#....#",
    "#######......#",
    "#............#",
    "#######~~#####",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 2, 6 }, ports = { right = "V" } },
    { kind = "source", at = { 10, 6 }, ports = { left = "N" } },
  },
  zone = function(x, y) return x >= 10 and not (x == 10 and y == 6) end,
  minMoves = 22,
}
