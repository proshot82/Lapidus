-- a1: «гнездо — дверь», муфта на дальнем уступе, старт длиной 5 головой у ниппеля
return {
  visibleLoss = dofile("build/l6c/a_f2plus/vis2.lua"),
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "###########",
    "####.#.####",
    "####......#",
    "####.#.##.#",
    "#.........#",
    "###########",
  },
  objects = {
    { kind = "source", at = { 2, 5 }, ports = { right = "N" } },
    { kind = "fixture", what = "heater", at = { 7, 2 }, ports = { down = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 9, 3 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 6, 3 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 7,5 }, { 6,5 }, { 5,5 }, { 5,4 }, { 5,3 } }, head = 5 },
  },
  ablations = dofile("build/l6c/a_f2plus/abl_door.lua"),
}
