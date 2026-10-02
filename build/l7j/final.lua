-- Квартира 7 «Зазор» — финалист раунда l7j, раунд e (кандидат e6, 02.10.2026). Решение не пишется.
-- Проверка: luajit build/l6b/check.lua build/l7j/final.lua; мёртвые клетки: luajit build/l6j/deadcells.lua build/l7j/final.lua
-- Поле 11×9, длина 2–5, напора нет. Детали: переходник (В слева, Н справа), угольник (В слева, Н вверх).
-- Прежний финалист («Надставка», c33) — build/l7j/final_c33.lua.
local okV, vis = pcall(dofile, "build/l6j/vis.lua")
return {
  visibleLoss = okV and vis or nil,
  id = 7, flat = 7, name = "Зазор",
  length = { 2, 5 }, pressure = 0, tile = "blue",
  target = { moves = { 15, 40 }, states = 100000, dead = 40, fb = 2 },
  grid = {
    "###########",
    "###########",
    "##...######",
    "##.#..#####",
    "##.#....###",
    "##....#.###",
    "##..#....##",
    "#.........#",
    "###########",
  },
  objects = {
    { kind = "source", at = { 2, 8 }, ports = { right = "N" } },
    { kind = "fixture", what = "sink", at = { 6, 4 }, ports = { down = "V" } },
    { kind = "fitting", what = "adapter", tag = "ada", at = { 4, 3 }, ports = { left = "V", right = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 7, 5 }, ports = { left = "V", up = "N" } },
    { kind = "lapidus", cells = { { 9, 8 }, { 10, 8 } }, head = 1 },
  },
  ablations = {
    { name = "без переходника", remove = "ada" },
    { name = "без угольника", remove = "elb" },
    { name = "угольник с самого начала в стояке", mutate = function(d) for _, o in ipairs(d.objects) do if o.tag == "elb" then o.at = { 3, 8 } end end end },
    { name = "угольник с самого начала под мойкой", mutate = function(d) for _, o in ipairs(d.objects) do if o.tag == "elb" then o.at = { 6, 5 } end end end },
  },
  -- Контроли (должны оставаться РЕШАЕМЫМИ; проверка — build/l7j/ctrl.lua).
  controls = {
    { name = "контроль: переходник с самого начала в стояке", mutate = function(d) for _, o in ipairs(d.objects) do if o.tag == "ada" then o.at = { 3, 8 } end end end },
    { name = "контроль: угольник с самого начала на полу у правой стены", mutate = function(d) for _, o in ipairs(d.objects) do if o.tag == "elb" then o.at = { 8, 8 } end end end },
  },
  texts = {
    request = "Раковина есть, вода есть, а вместе не встречаются. Как мы с тёщей.",
    card = nil, -- нового правила нет
    hints = {
      "Не всё, что подходит по резьбе, подходит по месту.",
      "Ваш звонок очень важен для нас. Уточняем, сколько звеньев у вашего Лапидуса.",
      "Мастер выехал. Говорит: зазор — это не брак, это место.",
    },
  },
}
