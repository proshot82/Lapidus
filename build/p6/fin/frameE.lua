return {
  grid = {
    "##############",
    "#######......#",
    "#######......#",
    "#######.#....#",
    "#######......#",
    "#............#",
    "#######~~#####",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 2, 6 }, ports = { right = "V" } },
    { kind = "source", at = { 10, 6 }, ports = { left = "N" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 10, 5 }, ports = { left = "N", right = "N" } },
  },
  zone = function(x, y) return x >= 11 end,
  minMoves = 18,
}
