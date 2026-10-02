-- Кв. 10 «Опрессовка», кандидат o33 (o29: ниппель правее лесенки, Лапидус у лесенки; роли переставлены — тройник на полке у левой дыры (всегда под рукой), переходник на полке справа, ниппель под лесенкой) — боковой стояк с конвейером (o20) + три дыры в полу полки: левая — в колодец над
-- тоннелем, средняя — лесенка Лапидуса (под ней лежит переходник: чтобы подняться, его надо сдвинуть к унитазу — ещё
-- шаг, и он прикрутится к унитазу), правая — сброс на карниз. Полка в два ряда. Решение здесь не пишется.
local okF, F = pcall(dofile, "build/l10a/filt10.lua")
if not okF then F = {} end
local okR, RL = pcall(dofile, "build/l10a/rules10.lua")
if not okR then RL = { RULES = {}, visibleLoss = function() return false end } end
return {
  id = 10, flat = 10, name = "Опрессовка",
  length = { 2, 6 }, pressure = 1, tile = "mustard",
  target = { moves = { 15, 40 }, states = 3000000, dead = 60, fb = 4 },
  visibleLoss = RL.visibleLoss, visRules = RL.RULES,
  grid = {
    "#############",
    "#######...###",
    "#####.....###",
    "#####.#.#.###",
    "#####......##",
    "#####.#######",
    "##.....######",
    "#############",
  },
  objects = {
    { kind = "source", at = { 7, 7 }, ports = { left = "N" } },
    { kind = "fixture", what = "sink", at = { 3, 7 }, ports = { right = "V" } },
    { kind = "fixture", what = "toilet", at = { 11, 5 }, ports = { left = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 9, 5 }, ports = { left = "N", right = "N" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 7, 3 }, ports = { right = "V", left = "V", up = "N" } },
    { kind = "fitting", what = "adapter", tag = "adp", at = { 9, 3 }, ports = { left = "V", right = "N" } },
    { kind = "lapidus", cells = { { 7, 5 }, { 8, 5 } }, head = 2 },
  },
  ablations = {
    { name = "без переходника", remove = "adp" },
    { name = "без ниппеля", remove = "nip" },
    { name = "без напора (конвейера нет)", pressure = 0 },
    { name = "тело не держит деталь", filter = F.noCarry },
    { name = "в дыру лесенки деталь не кладут", filter = F.noPieceAt and F.noPieceAt(8, 4) },
    { name = "Лапидус не ходит по тоннелю", filter = F.noBodyRow and F.noBodyRow(7) },
  },
  -- Контроли (должны оставаться решаемыми): запрет каждой ошибки плана — уровень решаем, ловушка снята.
  controls = {
    { name = "ниппель не к унитазу", filter = F.notAt and F.notAt("nip", 10, 5) },
    { name = "переходник не к унитазу", filter = F.notAt and F.notAt("adp", 10, 5) },
    { name = "переходник не раньше ниппеля", filter = F.notBefore and F.notBefore("adp", "nip") },
    { name = "тройник не раньше переходника", filter = F.notBefore and F.notBefore("tee", "adp") },
  },
  texts = { request = "Опрессовка.", card = nil, hints = { "—", "—", "—" } },
}
