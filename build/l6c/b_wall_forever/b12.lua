-- b12 «Дверь в стояке», широкая версия: левый верхний ход на клетку длиннее (четыре положения ниппеля до двери).
local V = { vis = dofile("build/l6c/b_wall_forever/vis_ic.lua")(7, 2, 8, 5) }
return {
  visibleLoss = V.vis,
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "############",
    "######.#####",
    "#.........##",
    "#.####.#.###",
    "#.........##",
    "#######.####",
    "#######.####",
    "#######.####",
    "############",
  },
  objects = {
    { kind = "source", at = { 7, 2 }, ports = { down = "N" } },
    { kind = "fixture", what = "heater", at = { 8, 8 }, ports = { up = "V" } },
    { kind = "fitting", what = "nipple", at = { 3, 3 }, tag = "pn", ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "coupling", at = { 8, 3 }, tag = "upc", ports = { up = "V", down = "V" } },
    { kind = "lapidus", cells = { { 7, 5 }, { 8, 5 }, { 9, 5 }, { 9, 4 }, { 9, 3 } }, head = 5 },
  },
  ablations = {
    -- роль «гнездо стояка — дверь для ниппеля»: ниппель не может попасть в гнездо или провалиться сквозь него
    { name = "ниппель не проходит сквозь гнездо", filter = function(lvl, st, ns)
        local C = 2 * lvl.W + 7
        for q, p in ipairs(lvl.pieces) do if p.tag == "pn" then
          local a, b = st.pos[q], ns.pos[q]
          if b == C then return false end
          if a ~= 0 and b ~= 0 and a <= C + (lvl.W - 7) and b > C and (b - 1) % lvl.W + 1 == 7 then return false end
        end end
        return true end },
  },
}
