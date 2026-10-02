-- kw1: kv_9_11_10 с латунной подставкой (заглушка) вместо мыла: выбивать можно любым концом
local okV, vis = pcall(dofile, "build/l8j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  washOk = true,
  mustLift = { "B" },
  id = 8, flat = 8, name = "kw1",
  length = { 2, 5 }, pressure = 0, tile = "mint",
  grid = {
    "#############",
    "##########.##",
    "########.#.##",
    "#..........##",
    "#..........##",
    "#####.###..##",
    "#####~###~~##",
  },
  objects = {
    { kind = "fixture", what = "sink", at = { 11, 2 }, ports = { down = "V" } },
    { kind = "source", at = { 9, 3 }, ports = { down = "N" } },
    { kind = "fitting", what = "adapter", tag = "B", at = { 5, 4 }, ports = { up = "N", down = "V" } },
    { kind = "fitting", what = "plug", tag = "A", at = { 5, 5 }, ports = { left = "V" } },
    { kind = "lapidus", cells = { { 3, 5 }, { 2, 5 }, { 2, 4 } }, head = 3 },
  },
  ablations = { },
}
