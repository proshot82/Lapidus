-- build/l2j/mk1.lua — перебор вариаций скелета «под лестницей» (b1): тоннель 1–2 ряда, правая шахта 1–2 клетки,
-- положение крюка A и унитаза, навес. Печатает строку метрик на вариант (без ходов).
package.path = "./?.lua;" .. package.path
local EV = dofile("build/l2j/ev.lua")
local function grid(W, H, walls)
  local g = {}
  for y = 1, H do
    local row = {}
    for x = 1, W do row[x] = (x == 1 or x == W or y == 1 or y == H) and "#" or "." end
    g[y] = row
  end
  for _, w in ipairs(walls) do g[w[2]][w[1]] = w[3] or "#" end
  local out = {}
  for y = 1, H do out[y] = table.concat(g[y]) end
  return out
end
local variants = {}
for _, tun in ipairs({ 1, 2 }) do
for _, shaftW in ipairs({ 1, 2 }) do
for _, over in ipairs({ false, true }) do
  if not (over and shaftW == 1) then
  local W = 8 + shaftW -- колонки: 1 граница, 2 стена, 3 шахта L? см. ниже
  -- схема: x=2 стена (стояк в (2,8)), x=3 левая шахта, x=4..5 блок (уступ), x=6.. правая шахта, затем стена, граница
  local H = 9
  local walls = {}
  for y = 2, 7 do walls[#walls + 1] = { 2, y } end
  local blockBottom = (tun == 1) and 7 or 6
  for y = 5, blockBottom do walls[#walls + 1] = { 4, y }; walls[#walls + 1] = { 5, y } end
  local rx = 6 + shaftW -- колонка правой стены
  for y = 2, 8 do walls[#walls + 1] = { rx, y } end
  if over then walls[#walls + 1] = { 6, 5 } end
  -- слив под тоннелем и шахтой
  for x = 4, rx - 1 do walls[#walls + 1] = { x, 9, "~" } end
  walls[#walls + 1] = { 3, 9 }
  local Acands = {}
  for y = 5, 7 do Acands[#Acands + 1] = { rx - 1, y, "left", "в стене" } end -- A в правой стене (занимает клетку шахты у стены)
  if shaftW == 2 then for y = 5, 7 do Acands[#Acands + 1] = { 6, y, "right", "у блока" } end end
  for _, A in ipairs(Acands) do
  for _, fy in ipairs({ 8 }) do
    local fx = rx - 1
    if A[1] == fx and A[2] == fy then goto continue end
    for _, cpl in ipairs({ 5, over and 6 or nil }) do
    for _, lap in ipairs({ "L", "R", "top" }) do
      local cells
      if lap == "L" then cells = { { 4, 4 }, { 4, 3 } } elseif lap == "R" then cells = { { 6, 4 }, { 6, 3 } } else cells = { { cpl, 3 }, { cpl, 2 } } end
      if lap == "R" and not over then goto nextlap end
      if lap == "L" and cpl == 4 then goto nextlap end
      local def = {
        length = { 2, 4 }, pressure = 0,
        grid = grid(W + 1, H, walls),
        objects = {
          { kind = "source", at = { 2, 8 }, ports = { right = "N" } },
          { kind = "fitting", what = "coupling", tag = "cpl", at = { cpl, 4 }, ports = { left = "V", right = "V" } },
          { kind = "fixture", what = "toilet", at = { fx, fy }, ports = { left = "N" } },
          { kind = "stub", tag = "A", at = { A[1], A[2] }, ports = { [A[3]] = "N" } },
          { kind = "lapidus", cells = cells, head = 2 },
        },
        ablations = { { name = "муфта", remove = "cpl" }, { name = "крюк", remove = "A" } },
      }
      -- стена под уступом должна быть стеной сетки: граница W+1
      local name = string.format("tun%d shaft%d over%s A(%d,%d,%s) cpl%d lap%s", tun, shaftW, tostring(over), A[1], A[2], A[3], cpl, lap)
      variants[#variants + 1] = { name, def }
      ::nextlap::
    end
    end
    ::continue::
  end
  end
  end
end end end
for _, v in ipairs(variants) do
  local ok, line = pcall(EV.line, v[2], 300000)
  print(v[1] .. " :: " .. (ok and line or ("ERR " .. tostring(line))))
end
