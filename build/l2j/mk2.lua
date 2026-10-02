-- build/l2j/mk2.lua — вариации скелета «Полка» (c1): глубина колодца, ряд стояка/унитаза, крюк в правой стене.
package.path = "./?.lua;" .. package.path
local EV = dofile("build/l2j/ev.lua")
local function build(D, sy, A, lap)
  local W, H = 8, D + 1
  local g = {}
  for y = 1, H do
    local row = {}
    for x = 1, W do row[x] = (x == 1 or x == W or y == 1 or y == H) and "#" or "." end
    g[y] = row
  end
  for x = 2, 7 do g[2][x] = "#" end
  g[3][2] = "#"; g[4][2] = "#"; g[3][7] = "#"; g[4][7] = "#"
  g[5][2] = "#"; g[5][5] = "#"; g[5][6] = "#"; g[5][7] = "#"
  for y = 6, D do g[y][2] = "#"; g[y][6] = "#"; g[y][7] = "#" end
  g[sy][2] = "."
  g[H][4] = "~"; g[H][5] = "~"
  local grid = {}
  for y = 1, H do grid[y] = table.concat(g[y]) end
  local objs = {
    { kind = "source", at = { 2, sy }, ports = { right = "V" } },
    { kind = "fixture", what = "toilet", at = { 3, sy + 1 }, ports = { right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 4, 3 }, ports = { left = "N", right = "N" } },
  }
  if A then grid[A[2]] = grid[A[2]]:sub(1, 5) .. "." .. grid[A[2]]:sub(7); objs[#objs + 1] = { kind = "stub", tag = "A", at = { 6, A[2] }, ports = { left = A[3] } } end
  objs[#objs + 1] = { kind = "lapidus", cells = lap, head = #lap }
  local abl = { { name = "ниппель", remove = "nip" } }
  if A then abl[#abl + 1] = { name = "крюк", remove = "A" } end
  return { length = { 2, 4 }, pressure = 0, grid = grid, objects = objs, ablations = abl }
end
local laps = { { { 4, 4 }, { 5, 4 }, { 5, 3 } }, { { 5, 3 }, { 5, 4 }, { 4, 4 } }, { { 4, 4 }, { 5, 4 } }, { { 5, 4 }, { 4, 4 } } }
for D = 8, 10 do
  for sy = 6, D - 1 do
    local As = { false }
    for r = 6, D do for _, th in ipairs({ "V", "N" }) do As[#As + 1] = { 6, r, th } end end
    for _, A in ipairs(As) do
      for li, lap in ipairs(laps) do
        local def = build(D, sy, A, lap)
        local ok, line = pcall(EV.line, def, 300000)
        local name = string.format("D%d sy%d A%s lap%d", D, sy, A and (A[2] .. A[3]) or "-", li)
        if ok and not line:match("НЕРЕШАЕМ") then print(name .. " :: " .. line) end
      end
    end
  end
end
