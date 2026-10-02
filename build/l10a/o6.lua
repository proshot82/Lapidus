-- Кв. 10 «Опрессовка», кандидат o6: одна комната, стояк в полу бьёт фонтаном высоты 1 — переправа деталей через
-- стояк, пока тройник её не закрыл. Детали разложены «не по своим сторонам»: угольник слева (нужен справа, под унитазом),
-- ниппель справа (нужен слева, у мойки). Ложный план — «сначала тройник на стояк». Решение здесь не пишется.
local okR, RL = pcall(dofile, "build/l10a/rules10.lua")
if not okR then RL = { RULES = {}, visibleLoss = function() return false end } end
return {
  id = 10, flat = 10, name = "Опрессовка",
  length = { 2, 5 }, pressure = 1, tile = "mustard",
  target = { moves = { 15, 40 }, states = 3000000, dead = 60, fb = 4 },
  visibleLoss = RL.visibleLoss, visRules = RL.RULES,
  grid = {
    "##############",
    "###..........#",
    "###..........#",
    "###..........#",
    "######.#######",
    "##############",
  },
  objects = {
    { kind = "source", at = { 7, 5 }, ports = { up = "N" } },
    { kind = "fixture", what = "sink", at = { 4, 4 }, ports = { right = "V" } },
    { kind = "fixture", what = "toilet", at = { 13, 3 }, ports = { down = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 5, 4 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 6, 4 }, ports = { up = "N", left = "V" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 8, 4 }, ports = { down = "V", left = "N", right = "N" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 9, 4 }, ports = { left = "N", right = "N" } },
    { kind = "lapidus", cells = { { 10, 4 }, { 11, 4 } }, head = 1 },
  },
  ablations = {
    { name = "без муфты", remove = "cpl" },
    { name = "без ниппеля", remove = "nip" },
    { name = "без угольника", remove = "elb" },
    { name = "без напора", pressure = 0 },
  },
  controls = {},
  texts = { request = "Опрессовка.", card = nil, hints = { "—", "—", "—" } },
}
