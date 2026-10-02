-- r3: r1, муфта у самой колонки (x=3).
local mk = dofile("build/l6c/e_orientation/mk.lua")
local A = dofile("build/l6c/e_orientation/abl_e.lua")
return mk{ vis = dofile("build/l6c/e_orientation/vis_e.lua"),
  grid = {
    "##########",
    "##.......#",
    "#........#",
    "#........#",
    "######~~##",
  },
  src = { 9, 4, "left", "N" }, fx = { 3, 2, "right", "V" },
  pieces = {
    { "cpl", "coupling", 3, 4, { left = "V", right = "V" } },
    { "nip", "nipple", 6, 3, { left = "N", right = "N" } },
  },
  lap = { { 6, 4 }, { 7, 4 }, { 8, 4 } }, head = 1,
  abl = {
    { name = "пара не держит муфту над сливом", filter = A.noBridge },
    { name = "ниппель не переходит муфту поверху", filter = A.noOver },
  },
}
