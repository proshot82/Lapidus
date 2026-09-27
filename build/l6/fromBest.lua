-- build/l6/fromBest.lua best.lua N — вернуть def для N-го кандидата из файла поиска
local path, N = ...
local list = dofile(path)
local c = list[tonumber(N)]
local W = #c.grid[1]
local function xy(i) return (i - 1) % W + 1, math.floor((i - 1) / W) + 1 end
local cells = {}
for k, i in ipairs(c.body) do local x, y = xy(i); cells[k] = { x, y } end
local nx, ny = xy(c.nip)
local spec = dofile(os.getenv("SPEC") or "build/l6/specB.lua")
local objs = {}
for _, o in ipairs(spec.objects) do
  local oo = {}
  for k, v in pairs(o) do oo[k] = v end
  if o.tag == spec.carry then oo.at = { nx, ny } end
  objs[#objs + 1] = oo
end
objs[#objs + 1] = { kind = "lapidus", cells = cells, head = #cells }
local grid = {}
for y, r in ipairs(c.grid) do grid[y] = r end
return { id = 6, flat = 6, name = spec.name, length = spec.length, pressure = 0, grid = grid, objects = objs,
  target = { moves = { 15, 40 }, states = 1000000, dead = 50, fb = 3 },
  ablations = { { name = "без ниппеля", remove = spec.carry } } }
