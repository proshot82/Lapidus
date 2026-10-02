-- Кв. 10 «Опрессовка», кандидат o13 — новое устройство «боковой стояк с конвейером»:
-- стояк в тупике нижнего тоннеля бьёт ВБОК (напор 1): деталь, упавшая в дыру перед ним, струя отгоняет к мойке —
-- детали заходят в тоннель только по одной, сверху, и встают в порядке падения (первая — к мойке). Тройник (В вправо,
-- Н влево, Н вверх) прикручивается к стояку сразу и закрывает дыру; его верхний выход — новый фонтан из дыры, и к нему
-- сверху заходит голова Лапидуса. Детали подают с двух этажей (полка и пол) — порядок падений выбирает игрок.
-- Унитаз на тумбе справа (вход снизу) — под него нужен угольник. Решение здесь не пишется.
local okR, RL = pcall(dofile, "build/l10a/rules10.lua")
if not okR then RL = { RULES = {}, visibleLoss = function() return false end } end
return {
  id = 10, flat = 10, name = "Опрессовка",
  length = { 2, 6 }, pressure = 1, tile = "mustard",
  target = { moves = { 15, 40 }, states = 3000000, dead = 60, fb = 4 },
  visibleLoss = RL.visibleLoss, visRules = RL.RULES,
  grid = {
    "##############",
    "#####.......##",
    "#####.####.###",
    "#####........#",
    "#####........#",
    "##.....#######",
    "##############",
  },
  objects = {
    { kind = "source", at = { 7, 6 }, ports = { left = "N" } },
    { kind = "fixture", what = "sink", at = { 3, 6 }, ports = { right = "V" } },
    { kind = "fixture", what = "toilet", at = { 13, 4 }, ports = { down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 8, 2 }, ports = { left = "N", right = "N" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 10, 2 }, ports = { right = "V", left = "N", up = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 8, 5 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 12, 5 }, ports = { up = "N", left = "V" } },
    { kind = "lapidus", cells = { { 9, 5 }, { 10, 5 } }, head = 1 },
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
