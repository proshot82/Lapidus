-- Квартира 2 «Скалолаз» — кандидат раунда 2 (build/l2e, 29.09.2026). Решение здесь не записано.
-- Ядро: крюк — точка отсчёта. От прикрученного конца дотягиваешься ровно на длину (Lmax − 1 = 3 клетки, «натянут»):
-- в коридор к стояку попадёшь только с крюка, стоящего в ряду коридора; с крюка на ряд ниже — на клетку не хватит.
-- Поле: слева вертикальный проход (унитаз сверху, стояк снизу, между ними шахта и коридор); посередине колодец с полом
-- (нижний ярус) и крючьями в обеих стенах; справа дымоход, где Лапидус начинает и по крюку выбирается на гребень стены.
-- В колодец с гребня можно только спуститься срывом, и на лету цепляет один конец: за какой крюк — решает игрок на
-- высоте, в середине пути. Ближний крюк (под самым коридором) — на ряд ниже, чем нужно: с него, как и с пола колодца
-- по нижним крючьям, «лестница» поднимается до соседней с коридором клетки и там кончается — натянут.
-- Видимый проигрыш (мерка новичка, только добавляет к tools/vislib.lua): Лапидус смыт или ни один его конец больше
-- никогда ни к чему не прикрутится (аналог правила «деталь больше не сдвинется»; мерка скептика build/l2v).
local VL = setmetatable({}, { __mode = "k" })
local function graph(lvl)
  local g = VL[lvl]
  if g then return g end
  local R = require("core.rules")
  local idx, keys, succ, grab = {}, {}, {}, {}
  local function add(k) local i = idx[k]; if not i then i = #keys + 1; keys[i] = k; idx[k] = i end; return i end
  add(R.key(R.newState(lvl)))
  local h = 1
  while h <= #keys do
    local st = R.decode(lvl, keys[h])
    local out = {}
    if not st.dead then
      local piece = R.occupancy(st)
      grab[h] = (R.endScrew(lvl, st, piece, "head") or R.endScrew(lvl, st, piece, "heel")) and true or false
      if not R.isWin(lvl, st) then
        for m = 1, 8 do
          local ns = R.move(lvl, st, R.MOVES[m].which, R.MOVES[m].dir)
          if ns then out[#out + 1] = add(R.key(ns)) end
        end
      end
    end
    succ[h] = out
    h = h + 1
  end
  local rev = {}
  for i = 1, #keys do for _, j in ipairs(succ[i]) do rev[j] = rev[j] or {}; rev[j][#rev[j] + 1] = i end end
  local ok, q, qh = {}, {}, 1
  for i = 1, #keys do if grab[i] then ok[i] = true; q[#q + 1] = i end end
  while qh <= #q do
    local j = q[qh]; qh = qh + 1
    for _, i in ipairs(rev[j] or {}) do if not ok[i] then ok[i] = true; q[#q + 1] = i end end
  end
  g = { R = R, idx = idx, ok = ok }
  VL[lvl] = g
  return g
end
local function visibleLoss(lvl, st)
  if st.dead then return true end
  local g = graph(lvl)
  local i = g.idx[g.R.key(st)]
  return not (i and g.ok[i])
end

-- Вспомогательное: было ли падение — повторяем ход из st и сравниваем тело до устаканивания с итогом.
local function fell(lvl, st, ns)
  local R = require("core.rules")
  local key = R.key(ns)
  for m = 1, 8 do
    local tr = {}
    local r = R.move(lvl, st, R.MOVES[m].which, R.MOVES[m].dir, tr)
    if r and R.key(r) == key then
      if r.dead then return true end
      local b0 = tr[1].state.body
      for k = 1, #b0 do if b0[k] ~= r.body[k] then return true end end
      return false
    end
  end
  return false
end
-- Ошибка подсказки №1: при спуске зацепиться за крюк ПОД коридором (он ближе к цели, но на ряд ниже) —
-- ход с падением, после которого конец прикручен к крюку с тегом "under", а до хода не был.
local function anchoredTo(lvl, st, tag)
  local R = require("core.rules")
  local piece = R.occupancy(st)
  for _, w in ipairs({ "head", "heel" }) do
    local q = R.endScrew(lvl, st, piece, w)
    if q and lvl.pieces[q].tag == tag then return true end
  end
  return false
end
local function hintError(lvl, st, ns)
  if ns.dead or not fell(lvl, st, ns) then return false end
  return anchoredTo(lvl, ns, "under") and not anchoredTo(lvl, st, "under")
end
-- Роль приёма: запрещено зацепиться на лету (падение, кончающееся прикрученным концом) — уровень обязан стать нерешаем.
local function noCatch(lvl, st, ns)
  if ns.dead or not fell(lvl, st, ns) then return true end
  local R = require("core.rules")
  local piece = R.occupancy(ns)
  return not (R.endScrew(lvl, ns, piece, "head") or R.endScrew(lvl, ns, piece, "heel"))
end
local function wallup(tag)
  return function(d)
    local keep = {}
    for _, o in ipairs(d.objects) do
      if o.tag == tag then
        local r = d.grid[o.at[2]]
        d.grid[o.at[2]] = r:sub(1, o.at[1] - 1) .. "#" .. r:sub(o.at[1] + 1)
      else keep[#keep + 1] = o end
    end
    d.objects = keep
  end
end

return {
  visibleLoss = visibleLoss, hintError = hintError,
  id = 2, flat = 2, name = "Скалолаз",
  length = { 2, 4 }, pressure = 0, tile = "blue",
  target = { moves = { 15, 40 }, states = 50000, dead = 25, fb = 0 },
  grid = {
    "###########",
    "#.#......##",
    "#.#...#...#",
    "#.#...#..##",
    "#........##",
    "#.....#..##",
    "###....####",
    "###...#####",
    "###...#####",
    "###########",
  },
  objects = {
    { kind = "fixture", what = "toilet", at = { 2, 2 }, ports = { down = "N" } },
    { kind = "source", at = { 2, 6 }, ports = { up = "V" } },
    { kind = "stub", tag = "top", at = { 10, 3 }, ports = { left = "N" } },  -- крюк дымохода
    { kind = "stub", tag = "row", at = { 7, 5 }, ports = { left = "V" } },   -- крюк в ряду коридора
    { kind = "stub", tag = "low", at = { 7, 7 }, ports = { left = "N" } },   -- нижний ярус
    { kind = "stub", tag = "under", at = { 3, 6 }, ports = { right = "V" } }, -- крюк под коридором: на ряд ниже, чем нужно
    { kind = "lapidus", cells = { { 8, 6 }, { 9, 6 } }, head = 2 },
  },
  ablations = {
    { name = "крючья замурованы", mutate = function(d) wallup("top")(d); wallup("row")(d); wallup("low")(d); wallup("under")(d) end },
    { name = "крюк ряда коридора резьбой Н", flip = "row" },
    { name = "зацепиться на лету нельзя", filter = noCatch },
  },
  texts = {
    request = "Унитаз на антресолях, стояк в подполе, между ними колодец. Верёвку не предлагать — я пробовал.",
    hints = {
      "Крюк — точка отсчёта: от него дотянешься ровно на длину. В коридор пустит крюк в его ряду, а не тот, что ближе, — под коридором на клетку не хватит.",
      "Ваш звонок очень важен для нас. Проверяем, не висите ли вы на ряд ниже, чем нужно.",
      "Мастер выехал. Держитесь за что-нибудь резьбовое.",
    },
  },
}
