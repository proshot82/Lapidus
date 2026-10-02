-- build/l2c/v0.lua — «БЫЛО»: нынешняя levels/02.lua без единой правки раскладки, только с честным видимым проигрышем
-- (та же мерка новичка, что у кандидатов k9/k11). Все тупики здесь — колодец под шахтой: яма глубже Лапидуса,
-- без крючьев; ни так, ни перевёрнутым не выбраться — видимый проигрыш.
-- Видимый проигрыш — мерка новичка (как в build/l1c): Лапидус смыт (здесь сливов нет) или выиграть нельзя ни так,
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
  visibleLoss = visibleLoss,
  id = 2, flat = 2, name = "Скалолаз",
  length = { 2, 4 }, pressure = 0, tile = "blue",
  target = { moves = { 15, 40 }, states = 50000, dead = 30, fb = 2 },
  grid = {
    "#########",
    "##......#",
    "#...#####",
    "#...##..#",
    "##......#",
    "##...####",
    "##...####",
    "##...####",
    "##...####",
    "#########",
  },
  objects = {
    { kind = "source", at = { 3, 2 }, ports = { right = "V" } },
    { kind = "fixture", what = "toilet", at = { 8, 2 }, ports = { left = "N" } },
    { kind = "stub", tag = "hook", at = { 2, 3 }, ports = { right = "V" } },
    { kind = "stub", tag = "hook", at = { 2, 4 }, ports = { right = "N" } },
    { kind = "lapidus", cells = { { 6, 5 }, { 7, 5 }, { 8, 5 } }, head = 3 },
  },
  ablations = { { name = "крючья замурованы", mutate = wallup("hook") }, { name = "резьба крючьев", flip = "hook" } },
  texts = {
    request = "Сижу на унитазе третью неделю. Жду воду. Не звоните в дверь.",
    hints = {
      "Отводы в шахте — скальные крючья: перехватывайтесь головой и ногами по очереди. Нижний крюк решает, каким концом начинать.",
      "Ваш звонок очень важен для нас. Проверяем, не висите ли вы зря.",
      "Мастер выехал. Держитесь за что-нибудь резьбовое.",
    },
  },
}
