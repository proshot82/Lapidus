-- вариант z: стопка «заглушка → переходник → тройник», мойка на уровне тройника; тройник раньше мойки в списке
local V = dofile("build/l7c/b_lift_cargo/vis.lua")
local function xy(s) local a, b = s:match("(%d+),(%d+)"); return { tonumber(a), tonumber(b) } end
local cells = {}
for a, b in (os.getenv("START") or "4,5;5,5;6,5;7,5"):gmatch("(%d+),(%d+)") do cells[#cells+1] = { tonumber(a), tonumber(b) } end
local grid = {}
for row in (os.getenv("GRID") or "###########/#####.#####/#####.#####/#####..####/##.....####/##........#/##..#.....#/#####.#####/###########"):gmatch("[^/]+") do grid[#grid+1] = row end
return {
  visibleLoss = V.make(os.getenv("VIS") or "mine"),
  id = 7, flat = 7, name = "Дали напор", length = { tonumber(os.getenv("LMIN") or 2), tonumber(os.getenv("LMAX") or 5) }, pressure = tonumber(os.getenv("PRESS") or 3),
  grid = grid,
  stack = { "plug", "adp", "tee" },
  objects = {
    { kind = "source", at = { 6, 8 }, ports = { up = "V" } },
    { kind = "fitting", what = "tee", tag = "tee", at = xy(os.getenv("TEE") or "5,6"), ports = { up = "N", right = "N", down = "V" } },
    { kind = "fixture", what = "sink", at = xy(os.getenv("FIX") or "7,4"), ports = { left = "V" } },
    { kind = "fitting", what = "plug", tag = "plug", at = xy(os.getenv("PLUG") or "7,7"), ports = { down = "V" } },
    { kind = "fitting", what = "adapter", tag = "adp", at = xy(os.getenv("ADP") or "8,7"), ports = { up = "N", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = xy(os.getenv("NIP") or "9,7"), ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = cells, head = #cells },
  },
}
