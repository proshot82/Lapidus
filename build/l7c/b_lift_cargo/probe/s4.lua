local V = dofile("build/l7c/b_lift_cargo/vis.lua")
local LEN = tonumber(os.getenv("LMAX") or 5)
local start = os.getenv("START") or "3,7;3,6;4,6"
local cells = {}
for a, b in start:gmatch("(%d+),(%d+)") do cells[#cells+1] = { tonumber(a), tonumber(b) } end
return {
  visibleLoss = V.make(os.getenv("VIS") or "mine"),
  id = 7, flat = 7, name = "Дали напор", length = { 2, LEN }, pressure = 3,
  grid = {
    "##########",
    "#####.####",
    "#####..###",
    "#####.####",
    "##.......#",
    "##.......#",
    "##..#....#",
    "#####.####",
    "##########",
  },
  objects = {
    { kind = "source", at = { 6, 8 }, ports = { up = "V" } },
    { kind = "fixture", what = "sink", at = { 7, 3 }, ports = { left = "V" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 5, 6 }, ports = { up = "N", right = "N", down = "V" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { 7, 7 }, ports = { down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 8, 7 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = cells, head = #cells },
  },
}
