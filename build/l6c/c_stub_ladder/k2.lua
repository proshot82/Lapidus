-- k2 (кв. 6 «Намертво», направление C «лестница на глухом отводе»). Решения здесь нет.
-- проба
return {
  visibleLoss = dofile("build/l6c/c_stub_ladder/vis.lua"),
  id = 6, flat = 6, name = "Намертво", length = { 3, 4 }, pressure = 0, tile = "mustard",
  grid = {
    "###########",
    "#####.#####",
    "###......##",
    "#####.##.##",
    "#####.##.##",
    "#####.#..##",
    "#.........#",
    "#####.##.##",
    "########~##",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 6, 2 }, ports = { down = "V" } },
    { kind = "source", at = { 6, 8 }, ports = { up = "V" } },
    { kind = "stub", at = { 10, 7 }, ports = { left = "N" } },
    { kind = "fitting", what = "coupling", tag = "A", at = { 5, 7 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "B", at = { 8, 3 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 2, 7 }, { 3, 7 }, { 4, 7 } }, head = 3 },
  },
}
