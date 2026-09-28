-- P3: стояк с двумя выходами (вправо — муфта для ног, вверх — пробка); колонка над нижним ходом (ниппель снизу).
-- Уголок 2×2 у стояка — место разворота; пробка его ломает, муфта отрезает от нижнего хода.
local function vis(lvl, st)
  for q, p in ipairs(lvl.pieces) do
    if p.movable and st.pos[q] ~= 0 and not st.fixed[q] then
      local b = lvl.nb[st.pos[q]][3]
      local onLap = false
      for _, c in ipairs(st.body) do if c == b then onLap = true end end
      local y = math.floor((st.pos[q] - 1) / lvl.W) + 1
      -- ниппель должен попасть в колонку снизу: если лежит на полу нижнего хода — не поднять
      if p.tag == "upn" and y == 5 and not onLap then return true end
    end
  end
  return false
end
local function objs(px, py, cx, cy, nx, ny)
  return {
    { kind = "source", at = { 2, 5 }, ports = { right = "N", up = "N" } },
    { kind = "fixture", what = "heater", at = { 6, 2 }, ports = { down = "V" } },
    { kind = "fitting", what = "plug", tag = "pp", at = { px, py }, ports = { down = "V" } },
    { kind = "fitting", what = "coupling", tag = "pc", at = { cx, cy }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "upn", at = { nx, ny }, ports = { up = "N", down = "N" } },
  }
end
return {
  length = { 3, 5 }, visibleLoss = vis, maxQ = 8,
  grid = {
    "##########",
    "#?###.####",
    "#...?.???#",
    "#.?##.#??#",
    "#........#",
    "##########",
  },
  objectSets = {
    objs(3, 3, 4, 5, 6, 4), objs(3, 3, 5, 5, 6, 4), objs(4, 3, 4, 5, 6, 4), objs(4, 3, 5, 5, 6, 4),
  },
  starts = {
    { cells = { { 5, 5 }, { 6, 5 }, { 7, 5 } }, head = 1 },
    { cells = { { 5, 5 }, { 6, 5 }, { 7, 5 } }, head = 3 },
    { cells = { { 6, 5 }, { 7, 5 }, { 8, 5 } }, head = 1 },
    { cells = { { 6, 5 }, { 7, 5 }, { 8, 5 } }, head = 3 },
    { cells = { { 6, 5 }, { 7, 5 }, { 8, 5 }, { 9, 5 } }, head = 1 },
    { cells = { { 6, 5 }, { 7, 5 }, { 8, 5 }, { 9, 5 } }, head = 4 },
  },
}
