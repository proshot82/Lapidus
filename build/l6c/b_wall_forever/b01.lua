-- b01 «Перевёрнутая С»: стояк в потолке — муфту поднимают снизу, и она перекрывает верхний ход;
-- колонка в полу — ниппель роняют в её лунку, и лунка перестаёт быть местом разворота.
local function vis(lvl, st)
  for q, p in ipairs(lvl.pieces) do
    if p.movable and st.pos[q] ~= 0 and not st.fixed[q] then
      -- муфта на полу нижнего хода (не на Лапидусе) — её уже не поднять к стояку
      if p.tag == "upc" then
        local b = lvl.nb[st.pos[q]][3]
        local y = math.floor((st.pos[q] - 1) / lvl.W) + 1
        local onLap = false
        for _, c in ipairs(st.body) do if c == b then onLap = true end end
        if y >= 5 and not onLap then return true end
      end
      -- ниппель провалился в лунку колонки и не свинтился / лежит в чужой яме
      if p.tag == "pn" then
        local x, y = (st.pos[q] - 1) % lvl.W + 1, math.floor((st.pos[q] - 1) / lvl.W) + 1
        if y >= 6 then return true end
        -- ниппель загнан в правый угол нижнего хода: встать справа от него нельзя (как ящик в углу)
        if y == 5 and x >= 8 then return true end
      end
    end
  end
  return false
end
return {
  visibleLoss = vis,
  id = 6, flat = 6, name = "Намертво", length = { 3, 5 }, pressure = 0, tile = "mustard",
  grid = {
    "##########",
    "####.#####",
    "#........#",
    "#.##.##.##",
    "#........#",
    "#####.####",
    "#####.####",
    "#####.####",
    "##########",
  },
  objects = {
    { kind = "source", at = { 5, 2 }, ports = { down = "N" } },
    { kind = "fixture", what = "heater", at = { 6, 8 }, ports = { up = "V" } },
    { kind = "fitting", what = "coupling", tag = "upc", at = { 4, 3 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "nipple", tag = "pn", at = { 7, 5 }, ports = { up = "N", down = "N" } },
    { kind = "lapidus", cells = { { 4, 5 }, { 5, 5 }, { 6, 5 } }, head = 3 },
  },
  ablations = {},
}
