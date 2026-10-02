-- Квартира 1 «Не той стороной» — кандидат build/l1c/w01.lua. эскиз: коридор, колодец с крюком, ниша
-- Решение здесь не пишется. Проверка: luajit build/l6b/check.lua <файл>; разбор: luajit build/l1c/an.lua <файл>.
-- Видимый проигрыш — мерка новичка (build/l1c): знает правила, но не решение. Видимо проиграно, если Лапидус
-- не может выиграть ни так, ни перевёрнутым концами (то же тело, голова ↔ ноги): «заперт в яме без выхода»,
-- смыт. Если перевёрнутым выиграть можно, проигрыш скрыт: выход есть, недостижима лишь ориентация («ага» уровня:
-- развернуться можно только повиснув на крюке). Живые состояния видимыми не помечаются никогда.
local VL = setmetatable({}, { __mode = "k" })
local function vlFlip(R, lvl, st)
  local s = R.clone(st)
  local b, n = s.body, #s.body
  for i = 1, math.floor(n / 2) do b[i], b[n + 1 - i] = b[n + 1 - i], b[i] end
  R.settle(lvl, s)
  return s
end
local function vlGood(lvl)
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
      add(R.key(vlFlip(R, lvl, st)))
    end
    succ[h] = out
    h = h + 1
  end
  local rev = {}
  for i = 1, #keys do for _, j in ipairs(succ[i]) do local r = rev[j]; if not r then r = {}; rev[j] = r end; r[#r + 1] = i end end
  local ok, q, qh = {}, {}, 1
  for i in pairs(win) do ok[i] = true; q[#q + 1] = i end
  while qh <= #q do local j = q[qh]; qh = qh + 1; for _, i in ipairs(rev[j] or {}) do if not ok[i] then ok[i] = true; q[#q + 1] = i end end end
  g = { R = R, idx = idx, ok = ok }
  VL[lvl] = g
  return g
end
local function visibleLoss(lvl, st)
  if st.dead then return true end
  local g = vlGood(lvl)
  local R = g.R
  local i = g.idx[R.key(st)]
  if i and g.ok[i] then return false end
  local j = g.idx[R.key(vlFlip(R, lvl, st))]
  return not (j and g.ok[j])
end
-- Абляции РОЛИ: крюк — единственная точка опоры для разворота.
local function noHook(lvl, st, ns)
  local R = require("core.rules")
  local piece = R.occupancy(ns)
  for _, which in ipairs({ "head", "heel" }) do
    local q = R.endScrew(lvl, ns, piece, which)
    if q and lvl.pieces[q].kind == "stub" then return false end
  end
  return true
end

return {
  visibleLoss = visibleLoss,
  id = 1, flat = 1, name = "Не той стороной",
  length = { 2, 4 }, pressure = 0, tile = "mint",
  target = { moves = { 15, 40 }, states = 20000, dead = 25, fb = 1 },
  grid = {
    "##########",
    "#......###",
    "######..##",
    "######...#",
    "######..##",
    "###.....##",
    "##########",
  },
  objects = {
    { kind = "source", at = { 8, 6 }, ports = { left = "N" } },
    { kind = "fixture", what = "bath", at = { 4, 6 }, ports = { right = "V" } },
    { kind = "stub", tag = "hook", at = { 9, 4 }, ports = { left = "N" } },
    { kind = "lapidus", cells = { { 3, 2 }, { 4, 2 }, { 5, 2 } }, head = 3 },
  },
  ablations = {
    { name = "без крюка", remove = "hook" },
    { name = "крюк без крепления", filter = noHook },
  },
  texts = {
    request = "Ванна есть. Воды нет. Прошу наоборот.",
    hints = {
      "Развернуться можно, только повиснув на чужой резьбе. Прикрутите сначала «не тот» конец.",
      "Ваш звонок очень важен для нас. Проверяем, есть ли у вас выход.",
      "Мастер выехал. Смотрите внимательно: второй раз он не приедет.",
    },
  },
}
