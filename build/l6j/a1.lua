-- a1: семейство A «табуретка → звено». Полка под потолком с ниппелем; муфта на полу у стояка.
-- Ложный план: муфту сразу в стояк (один толчок) — тогда на полку не забраться.
return {
  visibleLoss = dofile("build/l6j/vis.lua"),
  id = 6, flat = 6, name = "a1", length = { 2, 5 }, pressure = 0, tile = "mint",
  grid = {
    "###########",
    "#.........#",
    "#.........#",
    "#....##...#",
    "#....##...#",
    "#....##...#",
    "#....##...#",
    "#.........#",
    "###########",
  },
  objects = {
    { kind = "source", at = { 2, 8 }, ports = { right = "N" } },
    { kind = "fixture", what = "sink", at = { 10, 8 }, ports = { left = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 4, 8 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 7, 3 }, ports = { left = "N", right = "N" } },
    { kind = "lapidus", cells = { { 8, 8 }, { 9, 8 } }, head = 1 },
  },
  ablations = {
    { name = "без муфты", remove = "cpl" },
    { name = "без ниппеля", remove = "nip" },
  },
}
