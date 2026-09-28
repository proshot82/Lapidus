-- q1: колонка на левой стене (вход справа, В) на уровень выше пола; стояк за двойным сливом.
-- Ложный план: ниппель — в колонку (Н в В), муфту — в стояк. Муфта одна слив не перейдёт.
local mk = dofile("build/l6c/e_orientation/mk.lua")
return mk{ vis = dofile("build/l6c/e_orientation/vis_e.lua"),
  grid = {
    "#########",
    "#.......#",
    "#.......#",
    "#.......#",
    "#.......#",
    "#####~~##",
  },
  src = { 8, 5, "left", "N" }, fx = { 2, 4, "right", "V" },
  pieces = {
    { "cpl", "coupling", 4, 5, { left = "V", right = "V" } },
    { "nip", "nipple", 6, 4, { left = "N", right = "N" } },
  },
  lap = { { 5, 5 }, { 6, 5 }, { 7, 5 } }, head = 1,
}
