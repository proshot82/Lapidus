-- Квартира 6 «Кругом!» — финалист раунда «шея» (build/p6/neck, f1, 03.10.2026); слепой скептик: принять как лёгкую квартиру
-- середины. Сменила «Зазор» (build/l7j/installed_zazor_level4.lua, резерв). Решение не записано.
-- Раунд «шея» (build/p6/BRIEF.md, 03.10.2026): финалист, место — между кв. 6 и кв. 9. Источник: build/p6/neck/f1.lua.
-- Решение здесь не пишется. Проверка: luajit build/l6b/check.lua build/p6/neck/final.lua
local R = require("core.rules")
local function tagOf(lvl, tag) for q, p in ipairs(lvl.pieces) do if p.tag == tag then return q end end end
-- Абляция роли: пока угольник не прикручен, Лапидус не занимает угловую клетку колодца (3,5).
local function noCorner(lvl, st, ns)
  local q = tagOf(lvl, "elb")
  if ns.fixed[q] then return true end
  local c = R.idx(lvl, 3, 5)
  for _, b in ipairs(ns.body) do if b == c then return false end end
  return true
end
return {
  id = 6, flat = 6, name = "Кругом!",
  length = { 4, 6 }, pressure = 0, tile = "mint",
  target = { moves = { 18, 35 }, states = 100000, dead = 25, fb = 1 },
  grid = {
    "#########",
    "##......#",
    "##.######",
    "##.....##",
    "#....####",
    "#########",
  },
  objects = {
    { kind = "source", at = { 2, 5 }, ports = { right = "N" } },
    { kind = "fixture", what = "dryer", at = { 8, 2 }, ports = { left = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 4, 2 }, ports = { left = "V", up = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 5, 2 }, ports = { left = "V", right = "V" } },
    { kind = "lapidus", cells = { { 7, 4 }, { 7, 3 }, { 7, 2 }, { 6, 2 } }, head = 1 },
  },
  ablations = {
    { name = "без угольника", remove = "elb" },
    { name = "без муфты", remove = "cpl" },
    { name = "угольник сразу на стояке", mutate = function(d) for _, o in ipairs(d.objects) do if o.tag == "elb" then o.at = { 3, 5 } end end end },
    { name = "колодец 2x2 (без правой клетки низа)", mutate = function(d) d.grid[5] = "#...#####" end },
    { name = "колодец без средней клетки верха", mutate = function(d) d.grid[4] = "##.#...##" end },
    { name = "в углу колодца не стоят, пока угольник не на месте", filter = noCorner },
  },
  texts = {
    request = "Полотенцесушитель холодный. Полотенце сушу на себе, хожу задом наперёд: так спина сохнет быстрее.",
    card = nil, -- нового правила нет
    hints = {
      "Входить в квартиру надо головой вперёд. Это легче решить до того, как в прихожей появится мебель.",
      "Ваш звонок очень важен для нас. Уточните, каким концом вы обычно входите в квартиру.",
      "Мастер выехал. Перед выходом он всегда разворачивается в прихожей.",
    },
  },
}
