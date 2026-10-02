-- m1 (кв. 6 «Намертво», направление C «лестница на глухом отводе»). Решения здесь нет.
-- Замысел M1: ступенька на отводе перекрывает нижний коридор, поэтому сначала муфту надо прогнать мимо отвода
-- к стояку, и только потом ставить ступеньку. Отвод (В) и стояк (Н) ловят разные детали: муфта проходит над
-- отводом, переходник-ступенька проходит над стояком. Нижний ярус двухэтажный — Лапидус перелезает через детали.
return {
  visibleLoss = dofile("build/l6c/c_stub_ladder/vis.lua"),
  lift = { B = 3 },
  id = 6, flat = 6, name = "Намертво", length = { 3, 4 }, pressure = 0, tile = "mustard",
  grid = {
    "##########",
    "###.######",
    "###....###",
    "###.##.###",
    "###.##.###",
    "#........#",
    "#........#",
    "###.##.###",
    "##########",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 4, 2 }, ports = { down = "V" } },
    { kind = "source", at = { 4, 8 }, ports = { up = "N" } },
    { kind = "stub", at = { 7, 8 }, ports = { up = "V" } },
    { kind = "fitting", what = "nipple", tag = "B", at = { 5, 3 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "reducer", tag = "A", at = { 5, 7 }, ports = { up = "V", down = "N" } },
    { kind = "fitting", what = "coupling", tag = "C", at = { 8, 7 }, ports = { up = "V", down = "V" } },
    { kind = "lapidus", cells = { { 2, 7 }, { 3, 7 }, { 3, 6 } }, head = 3 },
  },
}
