-- CPT: доводка ядра «колонна-проход» (b08/b09) — стены «?» ради узкого живого коридора (теорема та же).
local vis = dofile("build/l6c/b_wall_forever/vis_ic.lua")(5, 2, 6, 5)
local function objs(nx, cx)
  return {
    { kind = "source", at = { 5, 2 }, ports = { down = "N" } },
    { kind = "fixture", what = "heater", at = { 6, 8 }, ports = { up = "V" } },
    { kind = "fitting", what = "nipple", tag = "pn", at = { nx, 3 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "coupling", tag = "upc", at = { cx, 3 }, ports = { up = "V", down = "V" } },
  }
end
return {
  length = { 3, 5 }, visibleLoss = vis, maxQ = 11,
  grid = {
    "##########",
    "####.#####",
    "#??.....?#",
    "#?##.#..?#",
    "#??.....?#",
    "#####.####",
    "#####.####",
    "#####.####",
    "##########",
  },
  objectSets = { objs(4, 6) },
  starts = {
    { cells = { { 7, 5 }, { 7, 4 }, { 7, 3 } }, head = 3 },
    { cells = { { 8, 5 }, { 7, 5 }, { 7, 4 }, { 7, 3 } }, head = 4 },
    { cells = { { 8, 4 }, { 8, 3 }, { 7, 3 } }, head = 3 },
  },
}
