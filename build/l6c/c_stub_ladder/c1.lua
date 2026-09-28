-- c1 (кв. 6 «Намертво», направление C «лестница на глухом отводе»). Решения здесь нет.
-- C1: цепочка по нижнему коридору: тройник к колонке, угольник на отвод (проверка механики)
return {
  visibleLoss = dofile("build/l6c/c_stub_ladder/vis.lua"),
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "###########",
    "#.........#",
    "#.........#",
    "#######.###",
    "#.........#",
    "#######.###",
    "###########",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 10, 5 }, ports = { left = "V" } },
    { kind = "source", at = { 6, 2 }, ports = { right = "N" } },
    { kind = "stub", at = { 8, 6 }, ports = { up = "N" } },
    { kind = "fitting", what = "tee", tag = "B", at = { 6, 5 }, ports = { left = "N", right = "N", up = "N" } },
    { kind = "fitting", what = "elbow", tag = "R", at = { 5, 5 }, ports = { down = "V", right = "V" } },
    { kind = "lapidus", cells = { { 2, 5 }, { 3, 5 }, { 4, 5 } }, head = 3 },
  },
}
