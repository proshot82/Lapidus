-- r8: r1 длиннее на клетку пола (пол 6 клеток), колонка под потолком на выступе (вход справа, В).
local mk = dofile("build/l6c/e_orientation/mk.lua")
local A = dofile("build/l6c/e_orientation/abl_e.lua")
return mk{ vis = dofile("build/l6c/e_orientation/vis_e.lua"),
  grid = {
    "###########",
    "###.......#",
    "#.........#",
    "#.........#",
    "#######~~##",
  },
  src = { 10, 4, "left", "N" }, fx = { 4, 2, "right", "V" },
  pieces = {
    { "cpl", "coupling", 5, 4, { left = "V", right = "V" } },
    { "nip", "nipple", 7, 3, { left = "N", right = "N" } },
  },
  lap = { { 7, 4 }, { 8, 4 }, { 9, 4 } }, head = 1,
  abl = {
    { name = "пара не держит муфту над сливом", filter = A.noBridge },
    { name = "ниппель не переходит муфту поверху", filter = A.noOver },
  },
}
