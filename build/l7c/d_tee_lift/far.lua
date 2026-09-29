-- far.lua — локальная доводка дальней стороны ядра «угольник глушит фонтан с дальней стороны» (семейство d0x).
-- Ближняя сторона, столб и тройник фиксированы; перебираются: пол дальней стороны (стена/слив в нижнем ряду),
-- одна-две стены над дальним полом, положение и резьба ванны. Фильтр — «ловушечный оракул»:
-- угольник вкручен с ближней стороны, заглушка на месте, Лапидус у ближней площадки → уровень обязан быть НЕРЕШАЕМ;
-- и сам уровень — решаем. Печатает выживших (без решений).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")

local function mkdef(floor9, walls, bath, bport, lap)
  local g = {}
  for y = 1, 9 do g[y] = {} for x = 1, 12 do g[y][x] = "." end end
  for x = 1, 12 do g[1][x] = "#"; g[9][x] = "#" end
  for y = 1, 9 do g[y][1] = "#"; g[y][12] = "#" end
  g[8][2] = "#"; g[5][3] = "#"
  for i, c in ipairs(floor9) do g[9][5 + i] = c end -- x = 6..11
  for _, w in ipairs(walls) do g[w[2]][w[1]] = "#" end
  local grid = {}
  for y = 1, 9 do grid[y] = table.concat(g[y]) end
  return {
    id = 7, name = "far", length = { 2, 5 }, pressure = 3, grid = grid,
    objects = {
      { kind = "source", at = { 3, 8 }, ports = { right = "V" } },
      { kind = "pipe", what = "tee", tag = "tee", at = { 4, 8 }, ports = { left = "N", up = "V", right = "V" } },
      { kind = "fitting", what = "plug", tag = "plug", at = { 3, 7 }, ports = { left = "N" } },
      { kind = "fitting", what = "elbow", tag = "elb", at = { 3, 6 }, ports = { down = "N", right = "N" } },
      { kind = "fixture", what = "bath", at = bath, ports = { [bport] = "V" } },
      { kind = "lapidus", cells = lap or { { 2, 7 }, { 2, 6 } }, head = 2 },
    },
  }
end

local function solvable(def, cap)
  local ok, lvl = pcall(R.compile, def)
  if not ok then return nil end
  if #R.validate(lvl) > 0 then return nil end
  local G = SV.explore(lvl, cap or 3000000)
  if not G then return "cap" end
  local r = G.firstWin and G.depth[G.firstWin] or false
  local n = G.n
  SV.freeGraph(G)
  return r, n
end

local traps = {
  { { 2, 7 }, { 3, 7 } }, { { 3, 7 }, { 2, 7 } },
  { { 2, 6 }, { 2, 7 }, { 3, 7 } }, { { 3, 7 }, { 2, 7 }, { 2, 6 } },
}
local function trapDead(floor9, walls, bath, bport)
  for _, lap in ipairs(traps) do
    local d = mkdef(floor9, walls, bath, bport, lap)
    for _, o in ipairs(d.objects) do
      if o.tag == "elb" then o.at = { 4, 7 } end
      if o.tag == "plug" then o.at = { 5, 8 } end
    end
    local r = solvable(d, 400000)
    if r ~= false then return false end
  end
  return true
end

local wallSet = { {}, { { 6, 6 } }, { { 7, 6 } }, { { 6, 5 } }, { { 7, 5 } }, { { 8, 6 } }, { { 6, 6 }, { 7, 6 } }, { { 7, 6 }, { 8, 6 } } }
local baths = {}
for x = 6, 9 do for y = 4, 8 do for _, p in ipairs({ "up", "down", "left", "right" }) do baths[#baths + 1] = { { x, y }, p } end end end
local floors = {}
for m = 0, 63 do
  local f = {}
  for i = 1, 6 do f[i] = (math.floor(m / 2 ^ (i - 1)) % 2 == 1) and "#" or "~" end
  floors[#floors + 1] = f
end
if FAR_LIB then return { mkdef = mkdef, trapDead = trapDead, solvable = solvable } end
local only = tonumber(arg[1]) -- номер набора стен (для деления прогона)
local found = 0
for wi, walls in ipairs(wallSet) do if not only or only == wi then
  for _, f in ipairs(floors) do
    for _, b in ipairs(baths) do
      local bx, by = b[1][1], b[1][2]
      local clash = false
      for _, w in ipairs(walls) do if w[1] == bx and w[2] == by then clash = true end end
      if not clash then
        if trapDead(f, walls, b[1], b[2]) then
          local d = mkdef(f, walls, b[1], b[2])
          local r, n = solvable(d, 1500000)
          if r and r ~= "cap" then
            found = found + 1
            local ws = {}
            for _, w in ipairs(walls) do ws[#ws + 1] = w[1] .. "," .. w[2] end
            print(string.format("floor=%s walls=[%s] bath=(%d,%d) %s | ходов %d, состояний %d", table.concat(f), table.concat(ws, " "), bx, by, b[2], r, n))
            io.stdout:flush()
          end
        end
      end
    end
  end
end end
print("найдено " .. found)
