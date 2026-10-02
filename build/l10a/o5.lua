-- Кв. 10 «Опрессовка», кандидат o5: o4 + угольник для унитаза (вход унитаза снизу, на тумбе над полом). Угольник
-- (Н вверх, В влево) по резьбе подходит и к правому выходу тройника, и к ниппелю, и под унитаз. Решение здесь не пишется.
local okR, RL = pcall(dofile, "build/l10a/rules10.lua")
if not okR then RL = { RULES = {}, visibleLoss = function() return false end } end
return {
  id = 10, flat = 10, name = "Опрессовка",
  length = { 2, 5 }, pressure = 1, tile = "mustard",
  target = { moves = { 15, 40 }, states = 3000000, dead = 60, fb = 4 },
  visibleLoss = RL.visibleLoss, visRules = RL.RULES,
  grid = {
    "#############",
    "###.........#",
    "###.........#",
    "###.........#",
    "######.######",
    "#############",
  },
  objects = {
    { kind = "source", at = { 7, 5 }, ports = { up = "N" } },
    { kind = "fixture", what = "sink", at = { 4, 4 }, ports = { right = "V" } },
    { kind = "fixture", what = "toilet", at = { 12, 3 }, ports = { down = "V" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 8, 4 }, ports = { down = "V", left = "N", right = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 6, 4 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 9, 4 }, ports = { left = "N", right = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 11, 4 }, ports = { up = "N", left = "V" } },
    { kind = "lapidus", cells = { { 10, 4 }, { 10, 3 } }, head = 2 },
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
