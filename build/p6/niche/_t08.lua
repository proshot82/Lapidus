-- Квартира 8 «Гусеница» — финалист раунда r (r13, 03.10.2026), слепой скептик: принять (тексты поправлены).
-- Прежняя версия с мылом — build/l8j/installed_q4_level8.lua. Источник: build/l8j/final.lua.
-- Квартира 8 «Гусеница» — финалист раунда l8j (02.10.2026), раунд r: раскладка r13 (прежние — final_q4.lua, final_p2.lua). Сменяет напорную «Гребёнку».
-- Проверка: luajit build/l6b/check.lua build/l8j/final.lua; отчёт — build/l8j/REPORT.md. Решение здесь не пишется.
-- Видимый проигрыш: общая линейка tools/vislib.lua + build/l8j/vis.lua.
local okV, vis = pcall(dofile, "build/l8j/vis.lua")
local R = require("core.rules")
local function tagOf(lvl, tag) for q, p in ipairs(lvl.pieces) do if p.tag == tag then return q end end end
local function onBody(st, c)
  for _, b in ipairs(st.body) do if b == c then return true end end
  return false
end
-- «везти на спине нельзя»: запрещён ход, который сдвигает муфту вбок, пока она лежит на Лапидусе
local function noConveyor(lvl, st, ns)
  local q = tagOf(lvl, "cpl")
  local a, b = st.pos[q], ns.pos[q]
  if a == 0 or b == 0 or st.fixed[q] then return true end
  local ax, ay = R.xy(lvl, a)
  local bx, by = R.xy(lvl, b)
  if ax ~= bx and onBody(st, lvl.nb[a][R.DOWN]) then return false end
  return true
end
-- «мимо стояка — только верхом»: муфта не опускается ниже ряда 4 правее старта
local function noDip(lvl, st, ns)
  local q = tagOf(lvl, "cpl")
  local c = ns.pos[q]
  if c == 0 or ns.fixed[q] then return true end
  local x, y = R.xy(lvl, c)
  return not (x >= 6 and y >= 5)
end
-- «пересадки нет»: муфта у колонки (столбцы 8–9, ряд 4) не может лежать на середине тела — только на конце
local function noHandover(lvl, st, ns)
  local q = tagOf(lvl, "cpl")
  local c = ns.pos[q]
  if c == 0 or ns.fixed[q] then return true end
  local x, y = R.xy(lvl, c)
  if y ~= 4 or x < 8 then return true end
  local b = lvl.nb[c][R.DOWN]
  local body = ns.body
  for k = 2, #body - 1 do if body[k] == b then return false end end
  return true
end
return {
  visibleLoss = okV and vis or nil,
  mustLift = { "cpl" },
  id = 8, flat = 8, name = "Гусеница",
  length = { 2, 5 }, pressure = 0, tile = "blue",
  target = { moves = { 15, 40 }, states = 100000, dead = 25, fb = 2 },
  grid = {
    "##########",
    "########.#",
    "######.###",
    "###......#",
    "##.......#",
    "####....##",
    "##########",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 9, 2 }, ports = { down = "N" } },
    { kind = "source", at = { 7, 3 }, ports = { down = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 5, 4 }, ports = { up = "V", down = "V" } },
    { kind = "lapidus", cells = { { 3, 5 }, { 4, 5 }, { 5, 5 } }, head = 3 },
  },
  ablations = {
        { name = "без муфты", remove = "cpl" },
    { name = "везти на спине нельзя", filter = noConveyor },
    { name = "мимо стояка только верхом", filter = noDip },
    { name = "пересадки нет", filter = noHandover },
      },
  texts = {
    request = "Колонку повесили под самый потолок, муфту положили мастеру на голову и ушли. Донести её он не может: ничего не носит.",
    card = "card10", -- вкладыш «Поднимает, но не носит»: здесь он впервые нужен
    hints = {
      "Донести муфту некому. Но если под ней лежите вы — она поедет, куда поползёте. Смотрите, что висит над дорогой.",
      "Ваш звонок очень важен для нас. Уточняем, что у вас висит над дорогой.",
      "Мастер выехал. Говорит: что проехало под стояком поверху, то к стояку и прикипело.",
    },
  },
}
