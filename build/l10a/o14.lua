-- Кв. 10 «Опрессовка», кандидат o14 — боковой стояк с конвейером (как o13), но без угольника: правая ветка — только
-- Лапидус (голова сверху в дыру к верхнему выходу тройника, ноги по карнизу к унитазу). Склады: полка (ряд 2) с двумя
-- дырами — левая над тоннелем, правая над карнизом; карниз (ряд 4); яма (ряд 5). Решение здесь не пишется.
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
    "#####.###.###",
    "#####.......#",
    "#####...#####",
    "##.....######",
    "#############",
  },
  objects = {
    { kind = "source", at = { 7, 6 }, ports = { left = "N" } },
    { kind = "fixture", what = "sink", at = { 3, 6 }, ports = { right = "V" } },
    { kind = "fixture", what = "toilet", at = { 11, 4 }, ports = { left = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 7, 2 }, ports = { left = "N", right = "N" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 9, 2 }, ports = { right = "V", left = "N", up = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 9, 4 }, ports = { left = "V", right = "V" } },
    { kind = "lapidus", cells = { { 7, 5 }, { 8, 5 } }, head = 1 },
  },
  ablations = {
    { name = "без муфты", remove = "cpl" },
    { name = "без ниппеля", remove = "nip" },
    { name = "без напора", pressure = 0 },
  },
  controls = {},
  texts = { request = "Опрессовка.", card = nil, hints = { "—", "—", "—" } },
}
