-- кандидат m3
local function q(lvl, tag) for i, p in ipairs(lvl.pieces) do if p.tag == tag then return i end end end
-- запрет: одна деталь закреплена, другая нет (ставить только парой)
local function onlyPair(lvl, st, ns)
  local c, n = q(lvl, "cpl"), q(lvl, "nip")
  return not (ns.pos[c] ~= 0 and ns.pos[n] ~= 0 and ns.fixed[c] ~= ns.fixed[n])
end
-- запрет: незакреплённый ниппель лежит на Лапидусе в столбце над ближней клеткой слива
local function noRide(lvl, st, ns)
  local n = q(lvl, "nip")
  local c = ns.pos[n]
  if c == 0 or ns.fixed[n] then return true end
  if (c - 1) % lvl.W + 1 ~= 8 then return true end
  local below = lvl.nb[c][3]
  for _, b in ipairs(ns.body) do if b == below then return false end end
  return true
end
return {
  id = 10, flat = 10, name = "n1", length = { 2, 6 }, pressure = 0, tile = "mustard",
  grid = {
    "##############",
    "#######.#....#",
    "#######......#",
    "#######.#.#..#",
    "#######.....##",
    "#............#",
    "#######~~#####",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 2, 6 }, ports = { right = "V" } },
    { kind = "source", at = { 10, 6 }, ports = { left = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 12, 5 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 11, 3 }, ports = { left = "N", right = "N" } },
    { kind = "lapidus", cells = { { 11, 6 }, { 12, 6 }, { 13, 6 } }, head = 1 },
  },
  ablations = {
    { name = "без муфты", remove = "cpl" },
    { name = "без ниппеля", remove = "nip" },
    { name = "только парой (муфта не идёт одна)", filter = onlyPair },
    { name = "ниппель не спускается на Лапидусе", filter = noRide },
  },
}
