-- Квартира 2 «Скалолаз» — АЛЬТЕРНАТИВНЫЙ кандидат (k11: как k9, но уступ длиннее — поле 11×10) доводки 29.09.2026 (build/l2c, журнал build/l2c/LOG.md). Решение здесь не пишется.
-- Идея прежняя: отводы в шахте — скальные крючья; подъём — перехватами головой и ногами по очереди, а нижний крюк
-- (резьба Н — берёт только голову) решает, каким концом начинать.
-- Что изменено против levels/02.lua и почему: в прежней раскладке все тупики были в колодце под шахтой — это
-- видимая яма, по мерке новичка скрытых тупиков 0 %. Ошибка «не тем концом» там ничего не стоила: ноги просто
-- не прикручивались, и Лапидус спокойно возвращался развернуться. Теперь разворот возможен только в комнатке
-- старта (карман над развилкой), а из неё к шахте ведёт жёлоб, по которому можно только упасть: на уступе и полке
-- у шахты развернуться негде, а назад в комнату не дотянуться. Шахта выше (5 крючьев над колодцем со сливом),
-- стояк — в стене над крючьями, унитаз — в конце короткого мостика над шахтой. Поле 11×10: уступ длиннее на две
-- клетки — скрытая ветка глубже на 2, но и путь по уступу без событий длиннее на 2.
-- Ложный план (подсказка №1 — «не тем концом»): спуститься ногами вперёд, раз они уже свешены в жёлоб. Ноги
-- приходят к шахте первыми, нижний крюк их не берёт, развернуться негде — и видно это не сразу.

-- Видимый проигрыш — мерка новичка (как в build/l1c): Лапидус смыт (слив на дне колодца) или выиграть нельзя ни так,
-- ни перевёрнутым концами (то же тело, голова ↔ ноги) — «заперт в яме без выхода». Если перевёрнутым выиграть можно,
-- проигрыш скрыт: не хватает только разворота, а это надо понять. Живые состояния не помечаются по построению
-- (из живого состояния выигрыш достижим «как есть»).
local VL = setmetatable({}, { __mode = "k" })
local function flipBody(R, lvl, st)
  local s = R.clone(st)
  local b, n = s.body, #s.body
  for i = 1, math.floor(n / 2) do b[i], b[n + 1 - i] = b[n + 1 - i], b[i] end
  R.settle(lvl, s)
  return s
end
local function winnable(lvl)
  local g = VL[lvl]
  if g then return g end
  local R = require("core.rules")
  local idx, keys, succ, win = {}, {}, {}, {}
  local function add(k) local i = idx[k]; if not i then i = #keys + 1; keys[i] = k; idx[k] = i end; return i end
  add(R.key(R.newState(lvl)))
  local h = 1
  while h <= #keys do
    local st = R.decode(lvl, keys[h])
    local out = {}
    if not st.dead then
      if R.isWin(lvl, st) then win[h] = true else
        for m = 1, 8 do
          local ns = R.move(lvl, st, R.MOVES[m].which, R.MOVES[m].dir)
          if ns then out[#out + 1] = add(R.key(ns)) end
        end
      end
      add(R.key(flipBody(R, lvl, st))) -- перевёрнутый двойник — в графе, но ходом с оригиналом не связан
    end
    succ[h] = out
    h = h + 1
  end
  local rev = {}
  for i = 1, #keys do for _, j in ipairs(succ[i]) do rev[j] = rev[j] or {}; rev[j][#rev[j] + 1] = i end end
  local ok, q, qh = {}, {}, 1
  for i in pairs(win) do ok[i] = true; q[#q + 1] = i end
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
  local g = winnable(lvl)
  local i = g.idx[g.R.key(st)]
  if i and g.ok[i] then return false end
  local j = g.idx[g.R.key(flipBody(g.R, lvl, st))]
  return not (j and g.ok[j])
end

-- Абляции (все обязаны быть нерешаемы). Контроли, которые обязаны быть решаемы, — в build/l2c/abl.lua:
-- «ногами вперёд падать нельзя» (ложный план запрещён — уровень решаем тем же числом ходов) и «резьба всех крючьев
-- перевёрнута» (тогда нижний крюк берёт ноги, и естественный спуск ногами вперёд становится рабочим).
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
-- роль приёма «начать головой»: запрещено упасть из комнаты старта так, что голова окажется ниже ног
local ROOM_X, ROOM_Y = 9, 3 -- комната старта: клетки x ≥ 9, y ≤ 3; ниже — жёлоб, уступ, полка
local function headFirstDrop(lvl, st, ns)
  local W = lvl.W
  local function yOf(c) return math.floor((c - 1) / W) + 1 end
  local inRoom = false
  for _, c in ipairs(st.body) do if (c - 1) % W + 1 >= ROOM_X and yOf(c) <= ROOM_Y then inRoom = true end end
  if not inRoom then return true end
  for _, c in ipairs(ns.body) do if yOf(c) <= ROOM_Y then return true end end
  return not (yOf(ns.body[#ns.body]) > yOf(ns.body[1]))
end
-- роль нижнего крюка: у самого нижнего крюка резьба В (голове внизу не за что взяться)
local function lowestHookV(d)
  local low
  for _, o in ipairs(d.objects) do if o.tag == "hook" and (not low or o.at[2] > low.at[2]) then low = o end end
  for k in pairs(low.ports) do low.ports[k] = "V" end
end

return {
  visibleLoss = visibleLoss,
  id = 2, flat = 2, name = "Скалолаз",
  length = { 2, 4 }, pressure = 0, tile = "blue",
  target = { moves = { 15, 40 }, states = 50000, dead = 30, fb = 2 },
  grid = {
    "###########",
    "#.....###.#",
    "#...####..#",
    "#...#####.#",
    "#...#####.#",
    "#...#####.#",
    "#...#.....#",
    "##....#####",
    "##...######",
    "##~~~######",
  },
  objects = {
    { kind = "source", at = { 2, 2 }, ports = { right = "V" } },
    { kind = "fixture", what = "toilet", at = { 6, 2 }, ports = { left = "N" } },
    { kind = "stub", tag = "hook", at = { 2, 3 }, ports = { right = "N" } },
    { kind = "stub", tag = "hook", at = { 2, 4 }, ports = { right = "V" } },
    { kind = "stub", tag = "hook", at = { 2, 5 }, ports = { right = "N" } },
    { kind = "stub", tag = "hook", at = { 2, 6 }, ports = { right = "V" } },
    { kind = "stub", tag = "hook", at = { 2, 7 }, ports = { right = "N" } },
    { kind = "lapidus", cells = { { 10, 5 }, { 10, 4 }, { 10, 3 }, { 9, 3 } }, head = 4 },
  },
  ablations = {
    { name = "крючья замурованы", mutate = wallup("hook") },
    { name = "головой вперёд не падать", filter = headFirstDrop },
    { name = "у нижнего крюка резьба В", mutate = lowestHookV },
  },
  texts = {
    request = "Сижу на унитазе третью неделю. Жду воду. Не звоните в дверь.",
    hints = {
      "Отводы в шахте — скальные крючья: перехватывайтесь головой и ногами по очереди. Нижний крюк решает, каким концом начинать.",
      "Ваш звонок очень важен для нас. Проверяем, не висите ли вы зря.",
      "Мастер выехал. Держитесь за что-нибудь резьбовое.",
    },
  },
}
