-- Кв. 10 «Опрессовка», кандидат o19 — боковой стояк с конвейером (см. o18), полка в два ряда (над деталями можно
-- пройти), тройник — на карнизе прямо перед Лапидусом (первое очевидное действие — столкнуть его в дыру).
-- Полка: переходник и ниппель; правая дыра полки роняет деталь на карниз. Решение здесь не пишется.
local okR, RL = pcall(dofile, "build/l10a/rules10.lua")
if not okR then RL = { RULES = {}, visibleLoss = function() return false end } end
return {
  id = 10, flat = 10, name = "Опрессовка",
  length = { 2, 6 }, pressure = 1, tile = "mustard",
  target = { moves = { 15, 40 }, states = 3000000, dead = 60, fb = 4 },
  visibleLoss = RL.visibleLoss, visRules = RL.RULES,
  grid = {
    "#############",
    "#####.....###",
    "#####.....###",
    "#####.###.###",
    "#####......##",
    "#####.#######",
    "##.....######",
    "#############",
  },
  objects = {
    { kind = "source", at = { 7, 7 }, ports = { left = "N" } },
    { kind = "fixture", what = "sink", at = { 3, 7 }, ports = { right = "V" } },
    { kind = "fixture", what = "toilet", at = { 11, 5 }, ports = { left = "V" } },
    { kind = "fitting", what = "adapter", tag = "adp", at = { 7, 3 }, ports = { left = "V", right = "N" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 9, 3 }, ports = { left = "N", right = "N" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 8, 5 }, ports = { right = "V", left = "V", up = "N" } },
    { kind = "lapidus", cells = { { 9, 5 }, { 10, 5 } }, head = 1 },
  },
  ablations = {
    { name = "без переходника", remove = "adp" },
    { name = "без ниппеля", remove = "nip" },
    { name = "без напора", pressure = 0 },
  },
  controls = {},
  texts = { request = "Опрессовка.", card = nil, hints = { "—", "—", "—" } },
}
