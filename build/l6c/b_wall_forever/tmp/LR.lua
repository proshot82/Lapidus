-- LR: муфта-крышка над ямой стояка (разворот только под ней) + кольцо, перекрытое ниппелем: ниппель вталкивают
-- под колонку только с дальней стороны кольца, и он режет кольцо. Два этапа: развернуться под муфтой, потом обход.
local function vis(lvl, st)
  for q, p in ipairs(lvl.pieces) do
    if p.movable and st.pos[q] ~= 0 and not st.fixed[q] then
      local y = math.floor((st.pos[q] - 1) / lvl.W) + 1
      local b = lvl.nb[st.pos[q]][3]
      local onLap = false
      for _, c in ipairs(st.body) do if c == b then onLap = true end end
      -- ниппель ниже верхнего хода (не на Лапидусе) — к колонке его уже не вернуть
      if p.tag == "pn" and y >= 4 and not onLap then return true end
      -- муфта не в своей яме и не над ней: лежит на полу нижнего хода
      if p.tag == "pc" and y == 5 and not onLap then return true end
    end
  end
  return false
end
return {
  length = { 3, 5 }, visibleLoss = vis, maxQ = 9,
  grid = {
    "##########",
    "######.###",
    "####?#..?#",
    "####.#.#.#",
    "#?.......#",
    "####.#####",
    "####.#####",
    "####.#####",
    "##########",
  },
  objectSets = {
    {
      { kind = "source", at = { 5, 8 }, ports = { up = "N" } },
      { kind = "fixture", what = "heater", at = { 7, 2 }, ports = { down = "V" } },
      { kind = "fitting", what = "coupling", tag = "pc", at = { 5, 4 }, ports = { up = "V", down = "V" } },
      { kind = "fitting", what = "nipple", tag = "pn", at = { 8, 3 }, ports = { up = "N", down = "N" } },
    },
  },
  starts = {
    { cells = { { 4, 5 }, { 5, 5 }, { 6, 5 }, { 7, 5 } }, head = 1 },
    { cells = { { 3, 5 }, { 4, 5 }, { 5, 5 }, { 6, 5 }, { 7, 5 } }, head = 1 },
    { cells = { { 5, 5 }, { 6, 5 }, { 7, 5 }, { 8, 5 } }, head = 1 },
    { cells = { { 5, 5 }, { 6, 5 }, { 7, 5 } }, head = 1 },
  },
}
