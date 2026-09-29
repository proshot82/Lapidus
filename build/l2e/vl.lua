-- build/l2e/vl.lua — видимый проигрыш для уровня без деталей, мерка новичка (кв. 2, раунд 2).
-- Видимо проиграно, если Лапидус смыт ИЛИ ни в одном достижимом будущем ни один его конец больше не прикрутится
-- ни к чему (аналог правила линейки «нужная деталь больше никогда не сдвинется» — мерка скептика build/l2v).
-- Только добавляет к tools/vislib.lua. Живые состояния не помечает по построению (из живого выигрыш = прикрутиться к прибору).
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
return function(lvl, st)
  if st.dead then return true end
  local g = graph(lvl)
  local i = g.idx[g.R.key(st)]
  return not (i and g.ok[i])
end
