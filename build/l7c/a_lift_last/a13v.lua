-- a13 (напор 3): «течь не затыкай — наращивай». Стояк бьёт вверх. Переходник вставляют сбоку в основание
-- (только слева — справа стена), угольник глушит надставленный фонтан сбоку на полке справа; ноги — в угольник,
-- голова — в ванну в конце полки. Переходник и угольник лежат на полке; через фонтан — только лифтом.
-- Видимый проигрыш (честный, узкий): деталь на полу у основания стояка (её уже не поднять); деталь, зажатая у ванны
-- или на ванне (её не сдвинуть никуда); деталь, закреплённая не в фонтане (например, в ванне).
local function visibleLoss(lvl, st)
  local W = lvl.W
  local function xy(c) return (c - 1) % W + 1, math.floor((c - 1) / W) + 1 end
  local sx, sy
  for _, p in ipairs(lvl.pieces) do if p.source then sx, sy = xy(p.start) end end
  local stuck = { ["9,6"] = true, ["10,5"] = true, ["10,4"] = true }
  for q, p in ipairs(lvl.pieces) do
    if p.movable and st.pos[q] ~= 0 then
      local x, y = xy(st.pos[q])
      if st.fixed[q] then
        if x ~= sx then return true end
      else
        if y >= sy or stuck[x .. "," .. y] then return true end
      end
    end
  end
  return false
end
return {
  visibleLoss = visibleLoss,
  id = 7, flat = 7, name = "Дали напор",
  length = { 2, 5 }, pressure = 3,
  grid = {
    "###########",
    "#.........#",
    "#.........#",
    "#.........#",
    "#.........#",
    "#.........#",
    "#....######",
    "#..#......#",
    "###########",
  },
  objects = {
    { kind = "source", at = { 5, 8 }, ports = { up = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 6, 6 }, ports = { down = "N", up = "V" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 7, 6 }, ports = { down = "N", right = "V" } },
    { kind = "fixture", what = "bath", at = { 10, 6 }, ports = { left = "N" } },
    { kind = "lapidus", cells = { { 9, 5 }, { 8, 5 } }, head = 2 },
  },
}
