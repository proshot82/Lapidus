-- b11 «Дверь в стояке»: b13 с доводкой правого края (верхний ход на две клетки дальше колонны, ниша под ним).
-- Гнездо под стояком — дверь; ниппель проходит сквозь неё, муфта запирает её навсегда; кольцо через дверь
-- исчезает вместе с ней — ориентация Лапидуса после установки муфты заперта.
local V = { vis = dofile("build/l6c/b_wall_forever/vis_ic.lua")(6, 2, 7, 5) }
return {
  visibleLoss = V.vis,
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "############",
    "#####.######",
    "#.........##",
    "#.###.#.#.##",
    "#........###",
    "######.#####",
    "######.#####",
    "######.#####",
    "############",
  },
  objects = {
    { kind = "source", at = { 6, 2 }, ports = { down = "N" } },
    { kind = "fixture", what = "heater", at = { 7, 8 }, ports = { up = "V" } },
    { kind = "fitting", what = "nipple", at = { 3, 3 }, tag = "pn", ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "coupling", at = { 7, 3 }, tag = "upc", ports = { up = "V", down = "V" } },
    { kind = "lapidus", cells = { { 6, 5 }, { 7, 5 }, { 8, 5 }, { 8, 4 }, { 8, 3 } }, head = 5 },
  },
  ablations = {
    -- роль «гнездо стояка — дверь для ниппеля»: ниппель не может попасть в гнездо или провалиться сквозь него
    { name = "ниппель не проходит сквозь гнездо", filter = function(lvl, st, ns)
        local C = 2 * lvl.W + 6
        for q, p in ipairs(lvl.pieces) do if p.tag == "pn" then
          local a, b = st.pos[q], ns.pos[q]
          if b == C then return false end
          if a ~= 0 and b ~= 0 and a <= C + (lvl.W - 6) and b > C and (b - 1) % lvl.W + 1 == 6 then return false end
        end end
        return true end },
  },
}
