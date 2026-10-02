-- Кв. 10 «Опрессовка», кандидат o18 — боковой стояк с конвейером, две полосы подачи в колодец над дырой:
-- полка (ряд 2, две дыры: левая — в колодец, правая — на карниз) и карниз (ряд 4, он же — дорога Лапидуса к унитазу).
-- Стояк в тупике тоннеля бьёт влево (напор 1): упавшая деталь отгоняется к мойке; детали встают в порядке падения.
-- Тройник (В–В, Н вверх) — единственная деталь, подходящая к стояку; закрыв дыру, он бьёт из неё вверх новым фонтаном.
-- Детали: ниппель (Н–Н) на карнизе, переходник (В–Н) и тройник на полке. Решение здесь не пишется.
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
    "#####......##",
    "#####.#######",
    "##.....######",
    "#############",
  },
  objects = {
    { kind = "source", at = { 7, 6 }, ports = { left = "N" } },
    { kind = "fixture", what = "sink", at = { 3, 6 }, ports = { right = "V" } },
    { kind = "fixture", what = "toilet", at = { 11, 4 }, ports = { left = "V" } },
    { kind = "fitting", what = "adapter", tag = "adp", at = { 7, 2 }, ports = { left = "V", right = "N" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 9, 2 }, ports = { right = "V", left = "V", up = "N" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 8, 4 }, ports = { left = "N", right = "N" } },
    { kind = "lapidus", cells = { { 9, 4 }, { 10, 4 } }, head = 1 },
  },
  ablations = {
    { name = "без переходника", remove = "adp" },
    { name = "без ниппеля", remove = "nip" },
    { name = "без напора", pressure = 0 },
  },
  controls = {},
  texts = { request = "Опрессовка.", card = nil, hints = { "—", "—", "—" } },
}
