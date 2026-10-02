-- r12: r9 длиннее на клетку пола (12×5), муфта в двух клетках от стены.
local mk = dofile("build/l6c/e_orientation/mk.lua")
local A = dofile("build/l6c/e_orientation/abl_e.lua")
return mk{ vis = dofile("build/l6c/e_orientation/vis_e.lua"),
  grid = {
    "############",
    "####.......#",
    "#..........#",
    "#..........#",
    "########~~##",
  },
  src = { 11, 4, "left", "N" }, fx = { 5, 2, "right", "V" },
  pieces = {
    { "cpl", "coupling", 4, 4, { left = "V", right = "V" } },
    { "nip", "nipple", 8, 3, { left = "N", right = "N" } },
  },
  lap = { { 8, 4 }, { 9, 4 }, { 10, 4 } }, head = 1,
  abl = {
    { name = "пара не держит муфту над сливом", filter = A.noBridge },
    { name = "ниппель не переходит муфту поверху", filter = A.noOver },
  },
}
