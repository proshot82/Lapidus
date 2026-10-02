-- IC3: муфта входит в потолочный стояк по верхнему ходу (толкнувший конец пойдёт назад последним);
-- её гнездо — верх средней шахты, единственного (кроме лунки колонки) места разворота; ниппель — крышка над лункой.
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
        local dir = (x < 7) and 4 or 2
        local behind = lvl.nb[st.pos[q]][dir]
        if behind == 0 or lvl.cell[behind] == 1 then return true end
      end
    end
  end
  return false
end
return {
  length = { 3, 5 }, visibleLoss = vis, maxQ = 10,
  grid = {
    "##########",
    "####.#####",
    "#....?####",
    "#.##.#.###",
    "#?......##",
    "######.###",
    "######.###",
    "######.###",
    "##########",
  },
  objectSets = {
    {
      { kind = "source", at = { 5, 2 }, ports = { down = "N" } },
      { kind = "fixture", what = "heater", at = { 7, 8 }, ports = { up = "V" } },
      { kind = "fitting", what = "coupling", tag = "upc", at = { 4, 3 }, ports = { up = "V", down = "V" } },
      { kind = "fitting", what = "nipple", tag = "pn", at = { 7, 4 }, ports = { up = "N", down = "N" } },
    },
  },
  starts = {
    { cells = { { 5, 5 }, { 6, 5 }, { 7, 5 }, { 8, 5 } }, head = 1 },
    { cells = { { 5, 5 }, { 6, 5 }, { 7, 5 }, { 8, 5 } }, head = 4 },
    { cells = { { 6, 5 }, { 7, 5 }, { 8, 5 } }, head = 1 },
    { cells = { { 6, 5 }, { 7, 5 }, { 8, 5 } }, head = 3 },
    { cells = { { 3, 5 }, { 4, 5 }, { 5, 5 }, { 6, 5 }, { 7, 5 } }, head = 1 },
    { cells = { { 3, 5 }, { 4, 5 }, { 5, 5 }, { 6, 5 }, { 7, 5 } }, head = 5 },
    { cells = { { 4, 5 }, { 5, 5 }, { 6, 5 }, { 7, 5 } }, head = 1 },
    { cells = { { 4, 5 }, { 5, 5 }, { 6, 5 }, { 7, 5 } }, head = 4 },
  },
}
