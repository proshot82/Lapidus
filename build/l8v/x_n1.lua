-- build/l8v/x_n1.lua — единственная решаемая раскладка scan.lua при длине 2–5 (варианты N и V совпадают): 18 ходов, 0 % скрытых, струя не обязательна — полка под пробкой перекрывает шею крана Q.
local F = dofile("build/l8a/filt.lua")
return {
  id = 8, flat = 8, name = "Брандспойт", length = { 2, 5 }, pressure = 2,
  grid = { "#############", "#####.......#", "#####...#...#", "####..#.....#", "#####.......#", "#####.......#", "#####.......#", "#####.......#", "#############" },
  objects = {
    { kind = "fitting", what = "plug", tag = "plug", at = { 7, 3 }, ports = { left = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 9, 2 }, ports = { left = "N", right = "N" } },
    { kind = "source", at = { 5, 4 }, ports = { right = "N" } },
    { kind = "source", at = { 11, 4 }, ports = { left = "V" } },
    { kind = "fixture", what = "bath", at = { 8, 8 }, ports = { up = "V" } },
    { kind = "lapidus", cells = { { 6, 8 }, { 7, 8 } }, head = 2 },
  },
  ablations = { { name = "брандспойт не бьёт", filter = F.noHose } },
}
