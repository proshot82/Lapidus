-- k17 (кв. 6 «Намертво», направление C «лестница на глухом отводе»). Решения здесь нет.
-- K17: шахта рядом (x=8), две муфты стопкой наверху, ниппель в стояк; голова слева
return {
  visibleLoss = dofile("build/l6c/c_stub_ladder/vis.lua"),
  id = 6, flat = 6, name = "Намертво", length = { 3, 4 }, pressure = 0, tile = "mustard",
  grid = {
    "###########",
    "#####..####",
    "#####...###",
    "#####.#.###",
    "#####.#.###",
    "#####.....#",
    "#####.#.###",
    "#####.#.###",
    "###########",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 6, 2 }, ports = { down = "N" } },
    { kind = "source", at = { 6, 8 }, ports = { up = "V" } },
    { kind = "stub", at = { 8, 8 }, ports = { up = "N" } },
    { kind = "fitting", what = "coupling", tag = "A", at = { 7, 3 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "coupling", tag = "B", at = { 7, 2 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "C", at = { 7, 6 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 8, 6 }, { 9, 6 }, { 10, 6 } }, head = 1 },
  },
}
