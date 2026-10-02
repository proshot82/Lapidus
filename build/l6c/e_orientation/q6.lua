-- q6: q5 с колонкой в среднем ряду (под колонкой — карман).
local mk = dofile("build/l6c/e_orientation/mk.lua")
local A = dofile("build/l6c/e_orientation/abl_e.lua")
return mk{ vis = dofile("build/l6c/e_orientation/vis_e.lua"),
  grid = {
    "#########",
    "#.......#",
    "#.......#",
    "#.......#",
    "#####~~##",
  },
  src = { 8, 4, "left", "N" }, fx = { 2, 3, "right", "V" },
  pieces = {
    { "cpl", "coupling", 4, 4, { left = "V", right = "V" } },
    { "nip", "nipple", 6, 3, { left = "N", right = "N" } },
  },
  lap = { { 5, 4 }, { 6, 4 }, { 7, 4 } }, head = 1,
  abl = {
    { name = "Лапидус не кран (деталь не поднять)", filter = A.noCrane },
    { name = "пара не держит муфту над сливом", filter = A.noBridge },
  },
}
