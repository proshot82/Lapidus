-- build/l2j/mk5.lua — случайные вариации коридорного скелета с двумя деталями (муфта В–В к стояку Н, ниппель Н–Н к ванне В),
-- полки/ямы/уступы; отбор по воротам раунда f. Печатает лучшие.
package.path = "./?.lua;" .. package.path
local EV = dofile("build/l2j/ev.lua")
math.randomseed(tonumber(arg[1]) or 7)
local N = tonumber(arg[2]) or 400
local W, H = 10, 7
local function gen()
  local g = {}
  for y = 1, H do g[y] = {} for x = 1, W do g[y][x] = (x == 1 or x == W or y == 1 or y == H) and "#" or "." end end
  -- стены-блоки в комнате: случайные 0..4 клетки в рядах 3..5
  local nb = math.random(0, 5)
  for _ = 1, nb do g[math.random(3, 5)][math.random(3, 8)] = "#" end
  -- ямы в полу
  if math.random() < 0.5 then g[H][math.random(3, 8)] = "~" end
  if math.random() < 0.3 then g[H][math.random(3, 8)] = "~" end
  local sy = math.random(4, 6); local fy = math.random(4, 6)
  g[sy][2] = "."; g[fy][9] = "."
  local free = {}
  for y = 2, H - 1 do for x = 3, 8 do if g[y][x] == "." then free[#free + 1] = { x, y } end end end
  local function pick() return table.remove(free, math.random(#free)) end
  local c, n = pick(), pick()
  local l1 = pick()
  local dirs = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
  local d = dirs[math.random(4)]
  local l2 = { l1[1] + d[1], l1[2] + d[2] }
  if l2[1] < 3 or l2[1] > 8 or l2[2] < 2 or l2[2] > H - 1 or g[l2[2]][l2[1]] ~= "." or (l2[1] == c[1] and l2[2] == c[2]) or (l2[1] == n[1] and l2[2] == n[2]) then return nil end
  local grid = {}
  for y = 1, H do grid[y] = table.concat(g[y]) end
  return { length = { 2, 4 }, pressure = 0, grid = grid, objects = {
    { kind = "source", at = { 2, sy }, ports = { right = "N" } },
    { kind = "fixture", what = "bath", at = { 9, fy }, ports = { left = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = c, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = n, ports = { left = "N", right = "N" } },
    { kind = "lapidus", cells = { l1, l2 }, head = 2 } },
    ablations = { { name = "муфта", remove = "cpl" }, { name = "ниппель", remove = "nip" } } }
end
local out = {}
for i = 1, N do
  local def = gen()
  if def then
    local ok, r = pcall(EV.eval, def, 150000)
    if ok and not r.err and not r.unsolvable and r.moves >= 10 and r.hidPct >= 20 and (r.width or 9) <= 3 then
      out[#out + 1] = { r.moves + r.hidPct / 10, def, EV.line(def, 150000) }
    end
  end
end
table.sort(out, function(a, b) return a[1] > b[1] end)
for i = 1, math.min(8, #out) do
  print(out[i][3])
  for _, row in ipairs(out[i][2].grid) do print("   " .. row) end
  for _, o in ipairs(out[i][2].objects) do if o.kind ~= "lapidus" then print("   ", o.kind, o.at[1], o.at[2]) else print("   lap", o.cells[1][1], o.cells[1][2], o.cells[2][1], o.cells[2][2]) end end
end
print("кандидатов", #out)
