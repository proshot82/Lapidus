-- tools/uniq2.lua 1 2 3 4 — где кратчайшие решения расходятся: ширина «коридора» кратчайших путей по
-- ходам и число развилок, которые сходятся обратно через два хода (перестановка независимых ходов).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local function succ(lvl, s)
  local out = {}
  if s.dead or R.isWin(lvl, s) then return out end
  for m = 1, 8 do
    local mv = R.MOVES[m]
    local ns = R.move(lvl, s, mv.which, mv.dir)
    if ns then out[#out + 1] = ns end
  end
  return out
end
for _, a in ipairs(arg) do
  local id = tonumber(a)
  local def = dofile(string.format("levels/%02d.lua", id))
  local lvl = R.compile(def)
  local s0 = R.newState(lvl)
  local k0 = R.key(s0)
  local dist, st, order, head, win = { [k0] = 0 }, { [k0] = s0 }, { k0 }, 1, nil
  while head <= #order and not win do
    local k = order[head]; head = head + 1
    for _, ns in ipairs(succ(lvl, st[k])) do
      local nk = R.key(ns)
      if dist[nk] == nil then
        dist[nk], st[nk] = dist[k] + 1, ns
        order[#order + 1] = nk
        if R.isWin(lvl, ns) then win = nk end
      end
    end
  end
  local best = dist[win]
  -- состояния на кратчайших путях: идём назад от победы по слоям
  local on = { [win] = true }
  local layer = { win }
  local width = { [best] = 1 }
  for d = best, 1, -1 do
    local prev, seen = {}, {}
    for _, k in ipairs(order) do
      if dist[k] == d - 1 and not seen[k] then
        for _, ns in ipairs(succ(lvl, st[k])) do
          if on[R.key(ns)] and dist[R.key(ns)] == d then seen[k] = true; prev[#prev + 1] = k; break end
        end
      end
    end
    for _, k in ipairs(prev) do on[k] = true end
    width[d - 1] = #prev
  end
  local spots, maxw = {}, 1
  for d = 0, best do
    if width[d] > 1 then spots[#spots + 1] = d; if width[d] > maxw then maxw = width[d] end end
  end
  print(string.format("кв. %d: ходов %d; развилки кратчайших путей после ходов: %s; наибольшая ширина %d",
    id, best, #spots > 0 and table.concat(spots, ", ") or "нет", maxw))
end
