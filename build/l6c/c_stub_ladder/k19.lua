-- k19 (кв. 6 «Намертво», направление C «лестница на глухом отводе»). Решения здесь нет.
-- K19: всё подаётся по нижнему коридору: муфта в стояк (ступенька колодца), муфта в шахту на отвод; ниппель наверху.
return {
  visibleLoss = dofile("build/l6c/c_stub_ladder/vis.lua"),
  id = 6, flat = 6, name = "Намертво", length = { 3, 4 }, pressure = 0, tile = "mustard",
  grid = {
    "###########",
    "######.####",
    "######...##",
    "######.#.##",
    "######.#.##",
    "#........##",
    "######.#.##",
    "######.#.##",
    "###########",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 7, 2 }, ports = { down = "V" } },
    { kind = "source", at = { 7, 8 }, ports = { up = "N" } },
    { kind = "stub", at = { 9, 8 }, ports = { up = "N" } },
    { kind = "fitting", what = "nipple", tag = "B", at = { 8, 3 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "coupling", tag = "A", at = { 5, 6 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "coupling", tag = "C", at = { 6, 6 }, ports = { up = "V", down = "V" } },
    { kind = "lapidus", cells = { { 2, 6 }, { 3, 6 }, { 4, 6 } }, head = 3 },
  },
}
