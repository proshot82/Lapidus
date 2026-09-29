-- Квартира 2 «Скалолаз» — кандидат k6 раунда 3 (build/l2e, 30.09.2026), после слепой проверки k4 (build/l2v2). Решение не записано.
-- Ядро прежнее: крюк — точка отсчёта, от якоря дотягиваешься ровно на длину (Lmax − 1 = 3, «натянут»); теперь оно
-- применено дважды. Ступень 1 — колодец с полом: в лаз в его стене пускает только крюк дальней стены, стоящий в ряду лаза;
-- крюк под лазом (ближний, на ряд ниже) — приманка. Ступень 2 — шахта за лазом: стояк и унитаз в её дальней стене выше
-- досягаемости с лаза, единственный якорь, с которого до них ровно длина, — крюк дальней стены под портами; крюк ближней
-- стены под лазом — вторая приманка (с неё до крюка-якоря не хватает клетки). Обе шахты с полом: срыв — нижний ярус.
-- Старт — на гребне стены между колодцем и правым простенком (дымохода больше нет).
-- Видимый проигрыш (мерка новичка, только добавляет к tools/vislib.lua): смыт или ни один конец больше никогда не прикрутится.
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
-- Ошибка подсказки №1: зацепиться за крюк ПОД лазом (ближний к цели, но на ряд ниже нужного) — в любой из двух ступеней:
-- ход с падением, после которого конец прикручен к крюку с тегом "under" (ступень 1) или "under2" (ступень 2), а до хода не был.
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
  for _, tag in ipairs({ "under", "under2" }) do
    if anchoredTo(lvl, ns, tag) and not anchoredTo(lvl, st, tag) then return true end
  end
  return false
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
    "#...#.....#",
    "#...#...###",
    "#...#...###",
    "##.......##",
    "##......###",
    "##......###",
    "##..#...###",
    "##..#...###",
    "###########",
  },
  objects = {
    { kind = "fixture", what = "toilet", at = { 2, 2 }, ports = { right = "N" } },
    { kind = "source", at = { 2, 3 }, ports = { right = "V" } },
    { kind = "stub", tag = "row", at = { 9, 5 }, ports = { left = "V" } },     -- ступень 1: крюк в ряду лаза (дальняя стена колодца)
    { kind = "stub", tag = "under", at = { 5, 6 }, ports = { right = "V" } },  -- ступень 1: приманка под лазом
    { kind = "stub", tag = "hook2", at = { 2, 4 }, ports = { right = "N" } },  -- ступень 2: единственный якорь под портами
    { kind = "stub", tag = "under2", at = { 5, 7 }, ports = { left = "V" } },  -- ступень 2: приманка под лазом с той стороны
    { kind = "lapidus", cells = { { 9, 2 }, { 10, 2 } }, head = 2 },
  },
  ablations = {
    { name = "замурован только крюк ряда лаза", mutate = wallup("row") },
    { name = "замурован только якорь шахты", mutate = wallup("hook2") },
    { name = "зацепиться на лету нельзя", filter = noCatch },
  },
  texts = {
    request = "Унитаз на антресолях, стояк под ним, а между — колодец и шахта. Верёвку не предлагать — я пробовал.",
    hints = {
      "Крюк — точка отсчёта: от него дотянешься ровно на длину. Пускает тот крюк, что стоит в нужном ряду, а не тот, что ближе, — под лазом на клетку не хватит. И так дважды.",
      "Ваш звонок очень важен для нас. Проверяем, не висите ли вы на ряд ниже, чем нужно.",
      "Мастер выехал. Держитесь за что-нибудь резьбовое.",
    },
  },
}
