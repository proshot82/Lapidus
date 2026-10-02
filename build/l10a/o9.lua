-- Кв. 10 «Опрессовка», кандидат o9: мойка в тоннеле (потолок над зазором закрыт), вход в тоннель — только через клетку
-- фонтана стояка. Деталь, вошедшая в фонтан, поднимается, если над ней пусто; под «крышкой» (другая деталь или тело
-- Лапидуса над фонтаном) её можно провести в тоннель. Тройник закрывает переправу навсегда. Унитаз на тумбе справа,
-- вход снизу — под него нужен угольник (Н вверх, В влево). Решение здесь не пишется.
local okR, RL = pcall(dofile, "build/l10a/rules10.lua")
if not okR then RL = { RULES = {}, visibleLoss = function() return false end } end
return {
  id = 10, flat = 10, name = "Опрессовка",
  length = { 2, 5 }, pressure = 1, tile = "mustard",
  target = { moves = { 15, 40 }, states = 3000000, dead = 60, fb = 4 },
  visibleLoss = RL.visibleLoss, visRules = RL.RULES,
  grid = {
    "##############",
    "######.......#",
    "###..........#",
    "######.#######",
    "##############",
  },
  objects = {
    { kind = "source", at = { 7, 4 }, ports = { up = "N" } },
    { kind = "fixture", what = "sink", at = { 4, 3 }, ports = { right = "V" } },
    { kind = "fixture", what = "toilet", at = { 13, 2 }, ports = { down = "V" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 8, 3 }, ports = { up = "N", left = "V" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 9, 3 }, ports = { down = "V", left = "N", right = "N" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 10, 3 }, ports = { left = "N", right = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 12, 3 }, ports = { left = "V", right = "V" } },
    { kind = "lapidus", cells = { { 11, 3 }, { 11, 2 } }, head = 2 },
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
