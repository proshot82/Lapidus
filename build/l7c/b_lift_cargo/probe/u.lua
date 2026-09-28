-- ядро «стопка в лифте», вариант u: детали из переменных окружения (PLUG, TEE, NIP как "x,y"), сетка GRID, старт START
local V = dofile("build/l7c/b_lift_cargo/vis.lua")
local function xy(s) local a, b = s:match("(%d+),(%d+)"); return { tonumber(a), tonumber(b) } end
local cells = {}
for a, b in (os.getenv("START")):gmatch("(%d+),(%d+)") do cells[#cells+1] = { tonumber(a), tonumber(b) } end
local grid = {}
for row in (os.getenv("GRID")):gmatch("[^/]+") do grid[#grid+1] = row end
return {
  visibleLoss = V.make(os.getenv("VIS") or "mine"),
  id = 7, flat = 7, name = "Дали напор", length = { 2, tonumber(os.getenv("LMAX") or 5) }, pressure = 3,
  grid = grid,
  objects = {
    { kind = "source", at = xy(os.getenv("SRC") or "6,8"), ports = { up = "V" } },
    { kind = "fixture", what = "sink", at = xy(os.getenv("FIX") or "7,3"), ports = { left = "V" } },
    { kind = "fitting", what = "tee", tag = "tee", at = xy(os.getenv("TEE")), ports = { up = "N", right = "N", down = "V" } },
    { kind = "fitting", what = "plug", tag = "plug", at = xy(os.getenv("PLUG")), ports = { down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = xy(os.getenv("NIP")), ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = cells, head = #cells },
  },
}
