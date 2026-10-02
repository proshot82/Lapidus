-- build/l2j/mk3.lua — «Полка» с прелюдией: ниппель на столбике в комнате над колодцем, Лапидус должен подставить спину.
package.path = "./?.lua;" .. package.path
local EV = dofile("build/l2j/ev.lua")
local function build(W, pillar, lap, hook)
  local H = 9
  local g = {}
  for y = 1, H do g[y] = {} for x = 1, W do g[y][x] = (x == 1 or x == W or y == 1 or y == H) and "#" or "." end end
  -- колодец: x=3..5, ряды 6..8; стояк (2,6), унитаз (3,7); пол комнаты ряд 5 при x>=5; шахты (3,5),(4,5) открыты
  for x = 2, W - 1 do g[5][x] = "#" end
  g[5][3] = "."; g[5][4] = "."
  for y = 6, 8 do for x = 2, W - 1 do g[y][x] = (x >= 3 and x <= 5) and "." or "#" end end
  g[6][2] = "."
  g[H][4] = "~"; g[H][5] = "~"
  for y = 2, 4 do g[y][2] = "#" end
  if pillar then g[pillar[2]][pillar[1]] = "#" end
  if hook then g[hook[2]][hook[1]] = "." end
  local grid = {}
  for y = 1, H do grid[y] = table.concat(g[y]) end
  local nipAt = pillar and { pillar[1], pillar[2] - 1 } or { 4, 3 }
  local objs = {
    { kind = "source", at = { 2, 6 }, ports = { right = "V" } },
    { kind = "fixture", what = "toilet", at = { 3, 7 }, ports = { right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = nipAt, ports = { left = "N", right = "N" } },
  }
  local abl = { { name = "ниппель", remove = "nip" } }
  if hook then objs[#objs + 1] = { kind = "stub", tag = "A", at = { hook[1], hook[2] }, ports = { [hook[3]] = hook[4] } }; abl[#abl + 1] = { name = "крюк", remove = "A" } end
  objs[#objs + 1] = { kind = "lapidus", cells = lap, head = #lap }
  return { length = { 2, 4 }, pressure = 0, grid = grid, objects = objs, ablations = abl }
end
local out = {}
for _, W in ipairs({ 8, 9 }) do
  local pillars = { false }
  for px = 3, W - 2 do for py = 3, 4 do pillars[#pillars + 1] = { px, py } end end
  for _, pl in ipairs(pillars) do
    local laps = {}
    for x = 3, W - 2 do
      laps[#laps + 1] = { { x, 4 }, { x + 1, 4 } }
      laps[#laps + 1] = { { x + 1, 4 }, { x, 4 } }
      laps[#laps + 1] = { { x, 4 }, { x, 3 } }
      laps[#laps + 1] = { { x, 3 }, { x, 4 } }
    end
    for _, lap in ipairs(laps) do
      local def = build(W, pl, lap, nil)
      local ok, r = pcall(EV.eval, def, 300000)
      if ok and not r.err and not r.unsolvable and true then
        out[#out + 1] = string.format("W%d pil%s lap(%d,%d)(%d,%d) :: %s", W, pl and (pl[1] .. "," .. pl[2]) or "-", lap[1][1], lap[1][2], lap[2][1], lap[2][2], EV.line(def, 300000))
      end
    end
  end
end
for _, l in ipairs(out) do print(l) end
print("всего", #out)
