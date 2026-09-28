-- p4: колонка под потолком (вход снизу), стояк за сливом справа; пара «ниппель — муфта» переходит слив
local mk = dofile("build/l6c/e_orientation/mk.lua")
return mk{ vis = dofile("build/l6c/e_orientation/vis_e.lua"),
  grid = {
    "#########",
    "#.......#",
    "#.......#",
    "#.......#",
    "#.......#",
    "######~##",
  },
  src = { 8, 5, "left", "N" }, fx = { 4, 2, "down", "V" },
  pieces = {
    { "cpl", "coupling", 3, 5, { left = "V", right = "V" } },
    { "nip", "nipple", 5, 4, { left = "N", right = "N" } },
  },
  lap = { { 4, 5 }, { 5, 5 }, { 6, 5 } }, head = 3,
}
