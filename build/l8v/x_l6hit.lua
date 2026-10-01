-- build/l8v/x_l6hit.lua — находка scan.lua при длине 2–6 (вариант V): семейство «ниппель на кране» становится решаемым (17 ходов, 14 % скрытых — класс «ниппель лёг на ванну»), но струя не обязательна. Решение не пишется.
local F = dofile("build/l8a/filt.lua")
return {
  id = 8, flat = 8, name = "Брандспойт", length = { 2, 6 }, pressure = 2,
  grid = { "#############", "#####.......#", "#####.#.#...#", "####........#", "#####.......#", "#####.......#", "#####.......#", "#####.......#", "#############" },
  objects = {
    { kind = "fitting", what = "plug", tag = "plug", at = { 7, 2 }, ports = { left = "N" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 9, 2 }, ports = { left = "N", right = "N" } },
    { kind = "source", at = { 5, 4 }, ports = { right = "V" } },
    { kind = "source", at = { 11, 4 }, ports = { left = "V" } },
    { kind = "fixture", what = "bath", at = { 8, 8 }, ports = { up = "V" } },
    { kind = "lapidus", cells = { { 6, 8 }, { 7, 8 } }, head = 2 },
  },
  ablations = { { name = "без пробки", remove = "plug" }, { name = "без ниппеля", remove = "nip" }, { name = "брандспойт не бьёт", filter = F.noHose } },
}
