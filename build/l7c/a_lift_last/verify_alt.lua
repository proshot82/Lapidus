-- Квартира 7 «Дали напор» — КОПИЯ кандидата L7A.lua для замера скептиком (28.09); отличается только visibleLoss
-- (build/l7c/a_lift_last, раскладка b10, 28.09.2026). Решение здесь не пишется.
-- Стояк течёт вверх фонтаном (напор 3); вход ванны смотрит прямо в струю. Фонтан держит на весу всё, что в него
-- попало, поэтому сам стояк глушится только сбоку. На фонтане с самого начала пляшет лишняя муфта, на антресоли —
-- переходник и угольник. Ложный план: «сначала заткнуть течь» — угольником сразу или муфтой сверху.
-- Ловушки (общими словами): муфта, вкрученная в ванну, ломает чётность резьбы; заглушённый раньше времени фонтан
-- больше ничего не поднимет; лишнюю муфту, скормленную фонтану не вовремя, уже не достать; переходник, сбитый
-- в карман, не вернуть.

-- Видимый проигрыш скептика (авторский узкий + деталь в углу кармана + запертый угольник; муфту в ванне НЕ помечает): см. build/l7c/a_lift_last/verify_vis.lua, вариант narrowPlus.
-- Проверка: luajit build/l7c/a_lift_last/verify_gates.lua build/l7c/a_lift_last/L7A.lua narrowPlus (живых помечено 0).
-- Замер скептика 28.09 (check.lua): СКРЫТЫХ 59 % | УМНАЯ ОБЕЗЬЯНА 0.02 % | ГЛУБИНА 10 у пути [11:10] — проходит,
--   но только потому, что муфта, вкрученная в ванну, здесь считается скрытой (автор в L7Aw считает её видимой).
local VV = dofile("build/l7c/a_lift_last/verify_vis.lua")
local function visibleLoss(lvl, st) return VV.narrowPlus(lvl, st) end

-- Абляции ролей (фильтры ходов): каждая запрещает одну роль фонтана или деталей — уровень становится нерешаемым.
local function tags(lvl) local Q = {}; for q, p in ipairs(lvl.pieces) do if p.tag then Q[p.tag] = q end end; return Q end
local function srcXY(lvl) for _, p in ipairs(lvl.pieces) do if p.source then return (p.start - 1) % lvl.W + 1, math.floor((p.start - 1) / lvl.W) + 1 end end end
local function XY(lvl, c) return (c - 1) % lvl.W + 1, math.floor((c - 1) / lvl.W) + 1 end
-- опора струи вверх: клетки столба и клетка над его верхушкой
local function onJet(lvl, st, c, inside)
  local R = require("core.rules")
  for _, j in ipairs(R.jets(lvl, st)) do
    if j.dir == 1 and #j.cells > 0 then
      for _, t in ipairs(j.cells) do if t == c then return true end end
      if not inside and lvl.nb[j.cells[#j.cells]][1] == c then return true end
    end
  end
  return false
end
-- фонтан не глотает муфту: муфта не бывает внутри действующей струи
local function noSwallow(lvl, st, ns)
  local Q = tags(lvl)
  local c = ns.pos[Q.cpl]
  return c == 0 or not onJet(lvl, ns, c, true)
end
-- фонтан не возит переходник: незакреплённый переходник не бывает на опоре струи
local function noRideAdp(lvl, st, ns)
  local Q = tags(lvl)
  local c = ns.pos[Q.adp]
  return c == 0 or ns.fixed[Q.adp] or not onJet(lvl, ns, c, false)
end
-- фонтан не возит угольник: незакреплённый угольник не бывает на опоре струи
local function noRideElb(lvl, st, ns)
  local Q = tags(lvl)
  local c = ns.pos[Q.elb]
  return c == 0 or ns.fixed[Q.elb] or not onJet(lvl, ns, c, false)
end
-- течь глушат первой: переходник не закрепить, пока угольник не закреплён
local function capFirst(lvl, st, ns)
  local Q = tags(lvl)
  return not (ns.fixed[Q.adp] and not ns.fixed[Q.elb])
end
-- муфту некуда отложить: муфта не бывает правее стояка
local function noPark(lvl, st, ns)
  local Q = tags(lvl); local sx = srcXY(lvl)
  local c = ns.pos[Q.cpl]; if c == 0 then return true end
  return (XY(lvl, c)) <= sx
end

return {
  id = 7, flat = 7, name = "Дали напор",
  length = { 2, 5 }, pressure = 3, tile = "mint",
  target = { moves = { 20, 45 }, states = 100000, dead = 50, fb = 3 },
  visibleLoss = visibleLoss,
  grid = {
    "#########",
    "#.....###",
    "#......##",
    "####....#",
    "#####...#",
    "#####...#",
    "#####.###",
    "#########",
  },
  objects = {
    { kind = "source", at = { 6, 7 }, ports = { up = "N" } },
    { kind = "fixture", what = "bath", at = { 5, 4 }, ports = { right = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 6, 3 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "adp", at = { 4, 3 }, ports = { left = "V", right = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 5, 3 }, ports = { down = "V", right = "V" } },
    { kind = "lapidus", cells = { { 7, 6 }, { 7, 5 } }, head = 2 },
  },
  ablations = {
    { name = "без угольника", remove = "elb" },
    { name = "фонтан не глотает муфту", filter = noSwallow },
    { name = "фонтан не возит переходник", filter = noRideAdp },
    { name = "фонтан не возит угольник", filter = noRideElb },
    { name = "течь глушат первой", filter = capFirst },
    { name = "муфту некуда отложить", filter = noPark },
  },
  texts = {
    request = "Дали напор. Бьёт в потолок, в ванну не попадает.",
    hints = {
      "Фонтан глушат последним: пока бьёт, он и лифт для переходника, и глотка для лишней муфты.",
      "Ваш звонок очень важен для нас. Проверяем, не вкрутили ли вы в ванну муфту вместо переходника.",
      "Мастер выехал. Стояк он глушит сбоку: кто глушит сверху, тот потом сушит усы.",
    },
  },
}
