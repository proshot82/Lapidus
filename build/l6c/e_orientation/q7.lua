-- q7: q2 шире на клетку: между муфтой и сливом две клетки пола (больше места «не с той стороны»).
local mk = dofile("build/l6c/e_orientation/mk.lua")
local A = dofile("build/l6c/e_orientation/abl_e.lua")
return mk{ vis = dofile("build/l6c/e_orientation/vis_e.lua"),
  grid = {
    "##########",
    "#####....#",
    "#........#",
    "#........#",
    "#........#",
    "######~~##",
  },
  src = { 9, 5, "left", "N" }, fx = { 2, 4, "right", "V" },
  pieces = {
    { "cpl", "coupling", 4, 5, { left = "V", right = "V" } },
    { "nip", "nipple", 7, 4, { left = "N", right = "N" } },
  },
  lap = { { 6, 5 }, { 7, 5 }, { 8, 5 } }, head = 1,
  abl = {
    { name = "Лапидус не кран (деталь не поднять)", filter = A.noCrane },
    { name = "пара не держит муфту над сливом", filter = A.noBridge },
  },
}
