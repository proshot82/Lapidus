-- Кв. 10 «Опрессовка», раунд 3, кандидат o55 (o52, воздух над карнизом 6–10): ядро o34 (унитаз В слева на карнизе), но над карнизом 7–9 ряд воздуха —
-- над ниппелем можно пройти (прогулка короче), правый сброс полки роняет деталь к унитазу (переходник к унитазу — дверь
-- с полки). Решение здесь не пишется.
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
    "#####.....###",
    "#####......##",
    "#####.#######",
    "##.....######",
    "#############",
  },
  objects = {
    { kind = "source", at = { 7, 8 }, ports = { left = "N" } },
    { kind = "fixture", what = "sink", at = { 3, 8 }, ports = { right = "V" } },
    { kind = "fixture", what = "toilet", at = { 11, 6 }, ports = { left = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 9, 6 }, ports = { left = "N", right = "N" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 7, 3 }, ports = { right = "V", left = "V", up = "N" } },
    { kind = "fitting", what = "adapter", tag = "adp", at = { 9, 3 }, ports = { left = "V", right = "N" } },
    { kind = "lapidus", cells = { { 6, 6 }, { 7, 6 } }, head = 2 },
  },
  ablations = {
    { name = "без переходника", remove = "adp" },
    { name = "без ниппеля", remove = "nip" },
    { name = "без напора (конвейера нет)", pressure = 0 },
  },
  -- Контроли (должны оставаться решаемыми): запрет каждой ошибки плана — уровень решаем, ловушка снята.
  controls = {
    { name = "ниппель не к унитазу", filter = F.notAt and F.notAt("nip", 10, 6) },
    { name = "переходник не к унитазу", filter = F.notAt and F.notAt("adp", 10, 6) },
    { name = "переходник не раньше ниппеля", filter = F.notBefore and F.notBefore("adp", "nip") },
    { name = "тройник не раньше переходника", filter = F.notBefore and F.notBefore("tee", "adp") },
    -- приёмы, без которых решение есть (решаемы — это не абляции): деталь на теле, деталь в дыре лесенки, ход по тоннелю
    { name = "тело не держит деталь", filter = F.noCarry },
    { name = "в дыру лесенки деталь не кладут", filter = F.noPieceAt and F.noPieceAt(8, 4) },
    { name = "Лапидус не ходит по тоннелю", filter = F.noBodyRow and F.noBodyRow(8) },
  },
  texts = {
    request = "Опрессовка в четверг. Стояк в подвале бьёт в стенку, мойка сухая, унитаз поставили на тумбу — говорят, так солиднее. Комиссия сказала: ни капли.",
    card = nil, -- новых правил нет (§6 «Ничего»)
    hints = {
      "Стояк бьёт вбок: что ни упадёт в дыру перед ним — отгонит к мойке, и детали встанут в порядке падения. Тройник закроет дыру навсегда — а подходит к стояку только он.",
      "Ваш звонок очень важен для нас. Уточните, что именно вы прикрутили к унитазу и кто теперь будет стоять у мойки.",
      "Мастер выехал. Говорит: с полки в подвал ведёт одна дыра, на карниз — другая, а третья — лесенка; кто упал первым, тот и у мойки.",
    },
  },
}
