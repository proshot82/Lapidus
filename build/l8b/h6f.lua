-- Кв. 8 «Брандспойт» — кандидат h6 (build/l8b, Fable, 01.10.2026), семейство Б2 «переходник на кране»: лучший измеренный
-- в рамке 16×10 / 2–6 / напор 3. Ворота 30.09 по ошибкам плана НЕ проходит (скрытых 0 %) — см. build/l8b/REPORT.md.
-- Решение здесь не пишется.
-- Устройство: кран Q (В, вправо) в левой стене на уровне ряда 5, над ним шахта (столбец 3) от полки под потолком;
-- кран X (В, влево) на тумбе справа, его шахта — правый край полки (столбец 9). На полке пробка (Н влево) и ниппель (Н,Н).
-- В полке две дыры (столбцы 5 и 7) — через них тело, повиснув на кране, выходит на полку. Ванна на полу (вход сверху).
-- «Ага» (M9 + M1 + M5): ни к одному крану головой не прикрутиться — оба с внутренней резьбой; ниппель, загнанный струёй
-- в дальний кран, даёт резьбу для головы, и только с этого якоря ноги достают до ванны. Струя бьёт прочь от крана, на котором
-- висишь: ниппель в X гонят, повиснув на Q; пробку в Q — уже повиснув головой на ниппеле (или ловят на себя).
local R = require("core.rules")
local F = dofile("build/l8a/filt.lua")
local function find(lvl, tag) for q, p in ipairs(lvl.pieces) do if p.tag == tag then return q end end end
return {
  id = 8, flat = 8, name = "Брандспойт",
  length = { 2, 6 }, pressure = 3, tile = "mint",
  target = { moves = { 15, 40 }, states = 50000, dead = 55, fb = 3 },
  grid = {
    "################",
    "################",
    "##.......#######",
    "##.#.#.#.#######",
    "#........#######",
    "##........######",
    "##.......#######",
    "##.......#######",
    "##.......#######",
    "################",
  },
  objects = {
    { kind = "source", at = { 2, 5 }, ports = { right = "V" } },
    { kind = "source", at = { 10, 6 }, ports = { left = "V" } },
    { kind = "fixture", what = "bath", at = { 6, 9 }, ports = { up = "V" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { 4, 3 }, ports = { left = "N" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 6, 3 }, ports = { left = "N", right = "N" } },
    { kind = "lapidus", cells = { { 3, 9 }, { 4, 9 } }, head = 2 },
  },
  -- Правило §7 (мерка новичка): деталь ниже полки и не прикручена — поднять нечем (только добавляет к общей линейке).
  visibleLoss = function(lvl, st)
    for q, p in ipairs(lvl.pieces) do
      if p.movable and st.pos[q] ~= 0 and not st.fixed[q] then
        local _, y = R.xy(lvl, st.pos[q])
        if y >= 5 then return true end
      end
    end
    return false
  end,
  ablations = {
    { name = "без пробки", remove = "plug" },
    { name = "без ниппеля", remove = "nip" },
    { name = "брандспойт не бьёт", filter = F.noHose },
    -- «ниппель не ловят на себя»: ниппель не лежит на теле Лапидуса (роль приёма «деталь на спине» — только для пробки)
    { name = "пробку не ловят на себя", filter = function(lvl, st, ns)
        if ns.dead then return true end
        local q = find(lvl, "plug")
        local c = ns.pos[q]
        if c == 0 or ns.fixed[q] then return true end
        local below = lvl.nb[c][3]
        for _, b in ipairs(ns.body) do if b == below then return false end end
        return true
      end },
  },
  controls = {
    { name = "к X ногами не прикручиваться", filter = function(lvl, st, ns)
        if ns.dead then return true end
        local w = R.water(lvl, ns)
        local xq
        for q, p in ipairs(lvl.pieces) do if p.source and p.x == 10 then xq = q end end
        return w.heelQ ~= xq
      end },
  },
  texts = {
    request = "Два крана торчат из стен, оба свищут, а резьба на обоих внутренняя — мне головой туда не влезть. Пробка и ниппель на антресоли. Ванна внизу. Я шланг, но не длинный.",
    card = "card08",
    hints = {
      "Струя бьёт прочь от крана, на котором висишь. Ниппель в дальний кран — а потом на нём и повиснуть: он даёт резьбу для головы.",
      "Ваш звонок очень важен для нас. Уточните, пожалуйста, на чём вы висите и что у вас при этом лежит на спине.",
      "Мастер выехал. Говорит: что падает в шахту на ноги — то и упадёт в кран, когда ноги уберёшь.",
    },
  },
}
