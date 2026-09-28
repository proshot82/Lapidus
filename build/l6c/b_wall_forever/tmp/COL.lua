-- COL: одна колонна — колонка вверху (5,2), стояк внизу (5,8); ход поперёк колонны на y=4; боковые карманы «?».
-- Трубу можно собрать тремя способами (порознь, обе снизу, обе сверху) — геометрия оставляет один.
local function vis(lvl, st)
  for q, p in ipairs(lvl.pieces) do
    if p.movable and st.pos[q] ~= 0 and not st.fixed[q] then
      local x, y = (st.pos[q] - 1) % lvl.W + 1, math.floor((st.pos[q] - 1) / lvl.W) + 1
      if x == 5 and y == 7 then return true end -- ниппель лёг на стояк: со дна не достать
      if y >= 5 and x ~= 5 then
        local b = lvl.nb[st.pos[q]][3]
        local onLap = false
        for _, c in ipairs(st.body) do if c == b then onLap = true end end
        if not onLap then return true end   -- деталь провалилась в боковой карман
      end
    end
  end
  return false
end
local function objs(cx, cy, nx, ny)
  return {
    { kind = "source", at = { 5, 8 }, ports = { up = "N" } },
    { kind = "fixture", what = "heater", at = { 5, 2 }, ports = { down = "V" } },
    { kind = "fitting", what = "coupling", tag = "pc", at = { cx, cy }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "pn", at = { nx, ny }, ports = { up = "N", down = "N" } },
  }
end
return {
  length = { 3, 4 }, visibleLoss = vis, maxQ = 10,
  grid = {
    "#########",
    "####.####",
    "####.####",
    "#.......#",
    "###?.?###",
    "###?.?###",
    "###?.?###",
    "####.####",
    "#########",
  },
  objectSets = { objs(3, 4, 7, 4), objs(7, 4, 3, 4), objs(2, 4, 3, 4), objs(7, 4, 8, 4) },
  starts = {
    { cells = { { 6, 4 }, { 7, 4 }, { 8, 4 } }, head = 1 },
    { cells = { { 6, 4 }, { 7, 4 }, { 8, 4 } }, head = 3 },
    { cells = { { 2, 4 }, { 3, 4 }, { 4, 4 } }, head = 1 },
    { cells = { { 2, 4 }, { 3, 4 }, { 4, 4 } }, head = 3 },
    { cells = { { 4, 4 }, { 5, 4 }, { 6, 4 } }, head = 1 },
    { cells = { { 4, 4 }, { 5, 4 }, { 6, 4 } }, head = 3 },
  },
}
