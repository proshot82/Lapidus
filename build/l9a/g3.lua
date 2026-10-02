-- Кв. 9 «Гребёнка», кандидат g3 (01.10.2026). Ядро «сухая гребёнка хватает, мокрая несёт»; ванна слева вверху со входом
-- справа — к ней достаёт только дальний столб; дальний гребень односторонний (вернуть деталь назад нельзя).
-- Гребёнка — две клетки трубы на полу с выходами вверх (U1, U2) и вправо (R); стояк под гребёнкой через
-- зазор, в зазор входит ниппель из нижней комнаты. Карниз слева на высоте второй клетки струи.
-- Решение здесь не пишется.
local okF, F = pcall(dofile, "build/l9a/filt.lua")
if not okF then F = {} end
-- Правило §7 «прибор навсегда занят деталью, чья резьба явно никуда не ведёт»: закреплённая деталь без второго
-- выхода (заглушка) на входе прибора — видимая потеря.
local R = require("core.rules")
local function visibleLoss(lvl, st)
  for q, p in ipairs(lvl.pieces) do
    if p.fixture then
      for d = 1, 4 do
        if p.ports[d] then
          local t = lvl.nb[st.pos[q]][d]
          for r, pr in ipairs(lvl.pieces) do
            if pr.movable and st.pos[r] == t and st.fixed[r] and pr.nports == 1 then return true end
          end
        end
      end
    end
  end
  return false
end
return {
  visibleLoss = visibleLoss,
  id = 9, flat = 9, name = "Гребёнка",
  length = { 3, 6 }, pressure = 2, tile = "blue",
  target = { moves = { 15, 40 }, states = 3000000, dead = 60, fb = 4 },
  grid = {
    "##############",
    "#####...######",
    "#####...######",
    "#####....#####",
    "#........#####",
    "#.####...#####",
    "#........#####",
    "#......#.#####",
    "######.#######",
    "##############",
  },
  objects = {
    { kind = "source", at = { 7, 9 }, ports = { up = "V" } },
    { kind = "pipe", what = "comb", tag = "m1", at = { 7, 7 }, ports = { down = "V", up = "N", right = "N" } },
    { kind = "pipe", what = "comb", tag = "m2", at = { 8, 7 }, ports = { left = "V", up = "N", right = "N" } },
    { kind = "fixture", what = "bath", at = { 6, 2 }, ports = { right = "V" } },
    { kind = "fixture", what = "toilet", at = { 9, 8 }, ports = { up = "N" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 4, 8 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { 5, 5 }, ports = { down = "V" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 6, 5 }, ports = { down = "V", left = "V" } },
    { kind = "lapidus", cells = { { 2, 5 }, { 3, 5 }, { 4, 5 } }, head = 3 },
  },
  ablations = {
    { name = "без заглушки", remove = "plug" },
    { name = "без угольника", remove = "elb" },
    { name = "фонтан не держит деталь", filter = F.noHover },
    { name = "деталь не едет по гребням", filter = F.noRide },
    { name = "деталь не вдавить сверху", filter = F.noPushDown },
  },
  controls = {
    { name = "детали не трогают всухую", filter = F.dryHandsOff },
  },
  texts = {
    request = "Поставили гребёнку. Ванна наверху, мойка внизу, воды нет ни в одной. Жена говорит — сначала ванна. Я говорю — сначала мойка. Решите вы.",
    card = "card09",
    hints = {
      "Сухая гребёнка хватает первую же деталь намертво. Сначала дай воду: фонтаны пронесут детали поверх выходов — к дальнему.",
      "Ваш звонок очень важен для нас. Уточните, какой из фонтанов вы заткнули первым.",
      "Мастер выехал. Говорит: что лежит на фонтане — не упало, а едет.",
    },
  },
}
