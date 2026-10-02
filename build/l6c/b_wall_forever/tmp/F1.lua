-- F1: муфта-крышка над ямой стояка на кольце; ниппель на верхнем ряду рядом с проходом под колонкой
-- честный видимый проигрыш: ниппель лежит ниже верхнего ряда не на Лапидусе (на полу, в яме, на муфте) —
-- к колонке его уже не поднять и не затолкать
local function vis(lvl, st)
  for q, p in ipairs(lvl.pieces) do
    if p.tag == "upn" and st.pos[q] ~= 0 and not st.fixed[q] then
      local x, y = (st.pos[q] - 1) % lvl.W + 1, math.floor((st.pos[q] - 1) / lvl.W) + 1
      if y > 3 then
        local b = lvl.nb[st.pos[q]][3]
        local onLap = false
        for _, c in ipairs(st.body) do if c == b then onLap = true end end
        if not onLap then return true end
      end
    end
  end
  return false
end
return {
  length = { 3, 5 }, visibleLoss = vis, maxQ = 9,
  grid = {
    "#########",
    "####.####",
    "#?......#",
    "#?.#.??.#",
    "#?......#",
    "##.###?##",
    "##.######",
    "##.######",
    "#########",
  },
  objects = {
    { kind = "source", at = { 3, 8 }, ports = { up = "N" } },
    { kind = "fixture", what = "heater", at = { 5, 2 }, ports = { down = "V" } },
    { kind = "fitting", what = "coupling", tag = "pc", at = { 3, 4 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "upn", at = { 6, 3 }, ports = { up = "N", down = "N" } },
  },
  starts = {
    { cells = { { 3, 5 }, { 4, 5 }, { 5, 5 }, { 6, 5 } }, head = 1 },
    { cells = { { 3, 5 }, { 4, 5 }, { 5, 5 }, { 6, 5 } }, head = 4 },
    { cells = { { 2, 5 }, { 3, 5 }, { 4, 5 } }, head = 1 },
    { cells = { { 2, 5 }, { 3, 5 }, { 4, 5 } }, head = 3 },
  },
}
