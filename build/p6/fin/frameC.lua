return {
  grid = {
    "#############",
    "#######.#...#",
    "#######.....#",
    "#...........#",
    "#######~~####",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 2, 4 }, ports = { right = "V" } },
    { kind = "source", at = { 10, 4 }, ports = { left = "N" } },
  },
  minMoves = 16,
}
