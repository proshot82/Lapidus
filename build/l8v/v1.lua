-- Кв. 8 «Брандспойт» — эскиз скептика v1 (build/l8v): «две пробки, три крана, порядок задаёт струя».
-- Устройство: кран A (Н, левая стена, ряд 4) и кран C (В, левая стена, ряд 6) надо заткнуть; кран B (Н, правая стена,
-- под потолком) — финальный якорь головы; ванна (В) в правой стене — ногами. Пробка-1 (В) на верхней полке — только струёй
-- с B, в шахту над A; пробка-2 (Н) на уступе — только телом, повиснув на A. Заложенная ошибка плана (общими словами):
-- кто сначала повиснет на B и собьёт пробку-1 (план кв. b5), тот больше не повиснет на A — и пробку-2 некому довести.
-- Поле 13×9, напор 3, длина 2–5, деталей 2. Решение здесь не пишется.
local F = dofile("build/l8a/filt.lua")
local R = require("core.rules")
return {
  id = 8, flat = 8, name = "Брандспойт",
  length = { 2, 5 }, pressure = 3, tile = "mint",
  target = { moves = { 15, 40 }, states = 50000, dead = 55, fb = 3 },
  grid = {
    "#############",
    "##..........#",
    "##.###.....##",
    "#...........#",
    "##.........##",
    "#..#.......##",
    "##.........##",
    "##.........##",
    "#############",
  },
  objects = {
    { kind = "source", at = { 2, 4 }, ports = { right = "N" } },
    { kind = "source", at = { 2, 6 }, ports = { right = "V" } },
    { kind = "source", at = { 12, 2 }, ports = { left = "N" } },
    { kind = "fixture", what = "bath", at = { 12, 4 }, ports = { left = "V" } },
    { kind = "fitting", what = "plug", tag = "plug1", at = { 6, 2 }, ports = { left = "V" } },
    { kind = "fitting", what = "plug", tag = "plug2", at = { 4, 5 }, ports = { left = "N" } },
    { kind = "lapidus", cells = { { 3, 8 }, { 4, 8 } }, head = 2 },
  },
  -- Правило §7 (мерка новичка): пробка на полу — поднять нечем.
  visibleLoss = function(lvl, st)
    for q, p in ipairs(lvl.pieces) do
      if p.movable and st.pos[q] ~= 0 and not st.fixed[q] then
        local _, y = R.xy(lvl, st.pos[q])
        if y == lvl.H - 1 then return true end
      end
    end
    return false
  end,
  ablations = {
    { name = "без пробки-1", remove = "plug1" },
    { name = "без пробки-2", remove = "plug2" },
    { name = "брандспойт не бьёт", filter = F.noHose },
  },
  texts = { request = "", card = "card07", hints = { "", "", "" } },
}
