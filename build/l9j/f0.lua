-- Квартира 9 «Домкрат» — финалист раунда l9j (02.10.2026), кандидат e2. Решение здесь не пишется.
-- Отчёт раунда — в ответе автора (среда не дала записать REPORT.md). Проверка: luajit build/l6b/check.lua build/l9j/final.lua
-- Видимый проигрыш: общая линейка tools/vislib.lua + build/l9j/vis9.lua; фильтры абляций роли — build/l9j/abl9.lua.
local okV, vis = pcall(dofile, "build/l9j/vis9.lua")
local okA, A = pcall(dofile, "build/l9j/abl9.lua")
return {
  visibleLoss = okV and vis or nil,
  id = 9, flat = 9, name = "Домкрат",
  length = { 3, 6 }, pressure = 0, tile = "mustard",
  target = { moves = { 15, 45 }, states = 300000, dead = 40, fb = 2 },
  grid = {
    "#########",
    "######.##",
    "#......##",
    "#..###.##",
    "#......##",
    "#..#.#.##",
    "#......##",
    "####~~.##",
    "#########",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 7, 2 }, ports = { down = "N" } },
    { kind = "source", at = { 7, 8 }, ports = { up = "N" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 6, 5 }, ports = { up = "V", down = "V", left = "N" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { 4, 5 }, ports = { right = "V" } },
    { kind = "lapidus", cells = { { 2, 7 }, { 3, 7 }, { 3, 6 } }, head = 3 },
  },
  ablations = {
    { name = "без заглушки", remove = "plug" },
    { name = "без тройника", remove = "tee" },
    { name = "тройник не поднимают", filter = okA and A.noLift("tee") or nil },
    { name = "заглушку не поднимают", filter = okA and A.noLift("plug") or nil },
    { name = "тройник сразу на стояке", mutate = function(d) for _, o in ipairs(d.objects) do if o.tag == "tee" then o.at = { 7, 7 } end end end },
    { name = "заглушка сразу на тройнике", mutate = function(d) for _, o in ipairs(d.objects) do if o.tag == "plug" then o.at = { 5, 5 } end end end },
    { name = "без лаза", mutate = function(d) d.grid[7] = "#....#.##" end },
  },
  texts = {
    request = "Колонку повесили под потолок, стояк вывели из пола прямо под ней, а соединить забыли. Тройник и заглушку оставили на полке — сказали, мастер разберётся.",
    hints = {
      "Тройнику место не на стояке: оттуда лишний выход смотрит на слив, и заглушку к нему не донести. А в колонку тройник сам не взлетит — поднимать придётся вам.",
      "Ваш звонок очень важен для нас. Уточняем, какой ногой вы держите тройник.",
      "Мастер выехал. Говорит: заглушку к тройнику на полу не крутят — такой бутерброд в шахту не пролезет.",
    },
  },
}
