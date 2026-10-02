-- B1T: ядро b01 — муфта входит в потолочный стояк по верхнему ходу и режет его (единственный путь за ниппель);
-- ниппель падает в лунку колонки и убивает последнее место разворота. Доводка: старты и позиции деталей.
local function vis(lvl, st)
  for q, p in ipairs(lvl.pieces) do
    if p.movable and st.pos[q] ~= 0 and not st.fixed[q] then
      local x, y = (st.pos[q] - 1) % lvl.W + 1, math.floor((st.pos[q] - 1) / lvl.W) + 1
      local b = lvl.nb[st.pos[q]][3]
      local onLap = false
      for _, c in ipairs(st.body) do if c == b then onLap = true end end
      if p.tag == "upc" and y >= 5 and not onLap then return true end
      if p.tag == "pn" and y >= 6 then return true end
      if p.tag == "pn" and y == 5 and not onLap then
        local dir = (x < 6) and 4 or 2
        local behind = lvl.nb[st.pos[q]][dir]
        if behind == 0 or lvl.cell[behind] == 1 then return true end
        if x > 6 and x >= 8 then return true end
      end
      if p.tag == "pn" and y <= 3 then return false end
    end
  end
  return false
end
local function objs(cx, cy, nx, ny)
  return {
    { kind = "source", at = { 5, 2 }, ports = { down = "N" } },
    { kind = "fixture", what = "heater", at = { 6, 8 }, ports = { up = "V" } },
    { kind = "fitting", what = "coupling", tag = "upc", at = { cx, cy }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "pn", at = { nx, ny }, ports = { up = "N", down = "N" } },
  }
end
return {
  length = { 3, 5 }, visibleLoss = vis, maxQ = 3,
  grid = {
    "##########",
    "####.#####",
    "#........#",
    "#.##.##?##",
    "#.......?#",
    "#####.####",
    "#####.####",
    "#####.####",
    "##########",
  },
  objectSets = {
    objs(4, 3, 7, 5), objs(3, 3, 7, 5), objs(4, 3, 7, 3), objs(3, 3, 7, 3), objs(6, 3, 7, 5), objs(7, 3, 7, 5),
    objs(4, 3, 3, 5), objs(6, 3, 3, 5), objs(4, 3, 8, 3),
  },
  starts = {
    { cells = { { 4, 5 }, { 5, 5 }, { 6, 5 } }, head = 1 },
    { cells = { { 4, 5 }, { 5, 5 }, { 6, 5 } }, head = 3 },
    { cells = { { 2, 5 }, { 3, 5 }, { 4, 5 } }, head = 1 },
    { cells = { { 2, 5 }, { 3, 5 }, { 4, 5 } }, head = 3 },
    { cells = { { 2, 3 }, { 2, 4 }, { 2, 5 } }, head = 1 },
    { cells = { { 2, 3 }, { 2, 4 }, { 2, 5 } }, head = 3 },
    { cells = { { 5, 4 }, { 5, 5 }, { 4, 5 }, { 3, 5 } }, head = 1 },
    { cells = { { 5, 4 }, { 5, 5 }, { 4, 5 }, { 3, 5 } }, head = 4 },
  },
}
