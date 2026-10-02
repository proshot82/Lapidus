-- build/l2j/mk4.lua — вариации e1: ряд крюка, ряд стояка, глубина колодца, где лежит ниппель, выступы в стенах.
package.path = "./?.lua;" .. package.path
local EV = dofile("build/l2j/ev.lua")
local function build(D, hr, sy, nipX, lap, notch)
  local W, H = 7, D + 1
  local g = {}
  for y = 1, H do g[y] = {} for x = 1, W do g[y][x] = (x == 1 or x == W or y == 1 or y == H or x == 2 or x == 6 or y == 2) and "#" or "." end end
  g[hr][6] = "."; g[sy][6] = "."
  g[H][3] = "~"; g[H][4] = "~"
  if notch then g[notch[2]][notch[1]] = "#" end
  local grid = {}
  for y = 1, H do grid[y] = table.concat(g[y]) end
  local objs = {
    { kind = "stub", tag = "H", at = { 6, hr }, ports = { left = "V" } },
    { kind = "source", at = { 6, sy }, ports = { left = "V" } },
    { kind = "fixture", what = "toilet", at = { 5, sy + 1 }, ports = { left = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { nipX, hr - 1 }, ports = { left = "N", right = "N" } },
    { kind = "lapidus", cells = lap, head = #lap },
  }
  return { length = { 2, 4 }, pressure = 0, grid = grid, objects = objs,
    ablations = { { name = "ниппель", remove = "nip" }, { name = "крюк", remove = "H" } } }
end
local best = {}
for D = 8, 9 do for hr = 3, 5 do for sy = hr + 2, D - 1 do
  local laps = { { { 5, hr }, { 4, hr }, { 3, hr } }, { { 5, hr }, { 4, hr } }, { { 5, hr }, { 4, hr }, { 4, hr + 1 } }, { { 5, hr }, { 4, hr }, { 4, hr + 1 }, { 3, hr + 1 } } }
  for li, lap in ipairs(laps) do for _, nipX in ipairs({ 4, 5 }) do
    local notches = { false }
    for y = hr + 1, sy - 1 do notches[#notches + 1] = { 3, y }; notches[#notches + 1] = { 5, y } end
    for _, nt in ipairs(notches) do
      local def = build(D, hr, sy, nipX, lap, nt)
      local ok, r = pcall(EV.eval, def, 200000)
      if ok and not r.err and not r.unsolvable and r.moves >= 8 then
        best[#best + 1] = { r.moves, string.format("D%d hr%d sy%d lap%d nip%d notch%s :: %s", D, hr, sy, li, nipX, nt and (nt[1] .. "," .. nt[2]) or "-", EV.line(def, 200000)) }
      end
    end
  end end
end end end
table.sort(best, function(a, b) return a[1] > b[1] end)
for i = 1, math.min(25, #best) do print(best[i][2]) end
print("всего", #best)
