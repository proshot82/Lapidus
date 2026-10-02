-- d1: «лифт и прокладка»: угольник (на стояке внизу) и муфта (к мойке наверху) — пара, которая не должна встретиться;
-- Лапидус ловит муфту на себя, поднимает ногами, голову опускает на угольник со сдвигом (S-образно). Поиск.
local okV, vis = pcall(dofile, "build/l6j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  id = 8, flat = 8, name = "d1",
  length = { 2, 5 }, pressure = 0, tile = "mint",
  grid = {
    "##########",
    "####.#####",
    "####.#####",
    "####.#####",
    "#........#",
    "####..####",
    "###...####",
    "##########",
  },
  objects = {
    { kind = "fixture", what = "sink", at = { 5, 2 }, ports = { down = "N" } },
    { kind = "source", at = { 4, 7 }, ports = { right = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 8, 5 }, ports = { left = "V", up = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 3, 5 }, ports = { up = "V", down = "V" } },
    { kind = "lapidus", cells = { { 7, 5 }, { 6, 5 } }, head = 2 },
  },
  ablations = { { name = "без угольника", remove = "elb" }, { name = "без муфты", remove = "cpl" } },
}
