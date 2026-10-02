-- Квартира 7 «Надставка» — финалист раунда l7j (кандидат c33, 02.10.2026). Решение не пишется.
-- Проверка: luajit build/l6b/check.lua build/l7j/final.lua; мёртвые клетки: luajit build/l6j/deadcells.lua build/l7j/final.lua
-- Поле 11×8, длина 2–5, напора нет. Детали: переходник (В слева, Н справа), угольник (В слева, Н вверх).
local okV, vis = pcall(dofile, "build/l6j/vis.lua")
local R = require("core.rules")
local function tagOf(lvl, tag) for q, p in ipairs(lvl.pieces) do if p.tag == tag then return q end end end
-- Абляция роли переходника: запрещены состояния, где клетка тела стоит прямо на закреплённом переходнике.
local function roleAda(lvl, st, ns)
  local q = tagOf(lvl, "ada")
  local c = ns.pos[q]
  if c == 0 or not ns.fixed[q] then return true end
  local up = lvl.nb[c][R.UP]
  for _, b in ipairs(ns.body) do if b == up then return false end end
  return true
end
-- Абляция роли угольника: незакреплённый угольник никогда не оказывается правее столбца, где он лежит.
local function roleElb(lvl, st, ns)
  local q = tagOf(lvl, "elb")
  local c = ns.pos[q]
  if c == 0 or ns.fixed[q] then return true end
  return (c - 1) % lvl.W + 1 <= 4
end
return {
  visibleLoss = okV and vis or nil,
  id = 7, flat = 7, name = "Надставка",
  length = { 2, 5 }, pressure = 0, tile = "blue",
  target = { moves = { 15, 40 }, states = 100000, dead = 40, fb = 2 },
  grid = {
    "###########",
    "##....#####",
    "##.##.#####",
    "##.....####",
    "##....#####",
    "##........#",
    "#.........#",
    "###########",
  },
  objects = {
    { kind = "source", at = { 2, 7 }, ports = { right = "N" } },
    { kind = "fixture", what = "sink", at = { 7, 4 }, ports = { left = "V" } },
    { kind = "fitting", what = "adapter", tag = "ada", at = { 9, 7 }, ports = { left = "V", right = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 4, 2 }, ports = { left = "V", up = "N" } },
    { kind = "lapidus", cells = { { 5, 2 }, { 6, 2 } }, head = 1 },
  },
  ablations = {
    { name = "без переходника", remove = "ada" },
    { name = "без угольника", remove = "elb" },
    { name = "роль переходника (фильтр)", filter = roleAda },
    { name = "роль угольника (фильтр)", filter = roleElb },
    { name = "угольник с самого начала в стояке", mutate = function(d) for _, o in ipairs(d.objects) do if o.tag == "elb" then o.at = { 3, 7 } end end end },
  },
  -- Контроли (должны оставаться РЕШАЕМЫМИ; проверка — build/l7j/ctrl.lua).
  controls = {
    { name = "контроль: переходник с самого начала в стояке", mutate = function(d) for _, o in ipairs(d.objects) do if o.tag == "ada" then o.at = { 3, 7 } end end end },
  },
  texts = {
    request = "Раковина сухая. Зубы чищу минералкой. Минералка кончилась, зубы — нет.",
    card = nil, -- нового правила нет
    hints = {
      "Угольник падает туда, куда его толкнули. Толкать его надо от стояка — а встать для этого не на что, пока переходник не при деле.",
      "Ваш звонок очень важен для нас. Уточняем, с какой стороны вы подходите к угольнику.",
      "Мастер выехал. Говорит: угольник прямо в стояк — и до раковины Лапидусу не хватит одного звена.",
    },
  },
}
