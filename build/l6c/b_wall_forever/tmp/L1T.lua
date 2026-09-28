-- L1T: две крышки (муфта над лункой стояка, ниппель над лункой колонки) на спине; лунки — единственные места разворота
local function vis(lvl, st)
  -- деталь трубы упала не в свою лунку (лежит на дне чужой ямы) — видно сразу
  for q, p in ipairs(lvl.pieces) do
    if p.movable and st.pos[q] ~= 0 and not st.fixed[q] then
      local y = math.floor((st.pos[q] - 1) / lvl.W) + 1
      if y >= 6 then return true end
    end
  end
  return false
end
return {
  length = { 3, 5 }, visibleLoss = vis, maxQ = 10,
  grid = {
    "############",
    "####.#.#?###",
    "#?........?#",
    "####.#.#?###",
    "###?.?.?####",
    "####.#.#####",
    "############",
  },
  objects = {
    { kind = "source", at = { 5, 6 }, ports = { up = "N" } },
    { kind = "fixture", what = "heater", at = { 7, 6 }, ports = { up = "V" } },
    { kind = "fitting", what = "coupling", tag = "pc", at = { 5, 2 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "pn", at = { 7, 2 }, ports = { up = "N", down = "N" } },
  },
  starts = {
    { cells = { { 4, 3 }, { 5, 3 }, { 6, 3 }, { 7, 3 }, { 8, 3 } }, head = 1 },
    { cells = { { 5, 3 }, { 6, 3 }, { 7, 3 }, { 8, 3 }, { 9, 3 } }, head = 1 },
    { cells = { { 3, 3 }, { 4, 3 }, { 5, 3 }, { 6, 3 }, { 7, 3 } }, head = 1 },
  },
}
