-- tools/monkey.lua 1 2 3 4 — «тест мартышки»: можно ли пройти уровень наобум. Случайный игрок делает
-- случайные допустимые ходы; «смыло» — откат хода; после 5×нормы ходов без успеха — «Заново».
-- Печатает долю успехов при разных бюджетах ходов. Решения не печатает.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
math.randomseed(12345)
for _, a in ipairs(arg) do
  local id = tonumber(a)
  local def = dofile(string.format("levels/%02d.lua", id))
  local lvl = R.compile(def)
  local s0 = R.newState(lvl)
  local ids, st, trans, win, dead, order = { [R.key(s0)] = 1 }, { s0 }, {}, {}, {}, { 1 }
  local head, dist = 1, { 0 }
  while head <= #order do
    local i = order[head]; head = head + 1
    local s = st[i]
    trans[i] = {}
    win[i] = (not s.dead) and R.isWin(lvl, s)
    dead[i] = s.dead
    if not win[i] and not dead[i] then
      for m = 1, 8 do
        local mv = R.MOVES[m]
        local ns = R.move(lvl, s, mv.which, mv.dir)
        if ns then
          local k = R.key(ns)
          local j = ids[k]
          if not j then j = #st + 1; ids[k] = j; st[j] = ns; order[#order + 1] = j; dist[j] = dist[i] + 1 end
          trans[i][#trans[i] + 1] = j
        end
      end
    end
  end
  local opt = math.huge
  for i = 1, #st do if win[i] and dist[i] < opt then opt = dist[i] end end
  local function trial(budget)
    local cur, steps, since = 1, 0, 0
    while steps < budget do
      local out = trans[cur]
      if #out == 0 then cur, since = 1, 0 end
      local nxt = trans[cur][math.random(#trans[cur])]
      steps, since = steps + 1, since + 1
      if win[nxt] then return true, steps end
      if not dead[nxt] then cur = nxt end
      if since >= 5 * opt then cur, since = 1, 0 end
    end
    return false, steps
  end
  local line = {}
  for _, budget in ipairs({ 300, 1000, 3000 }) do
    local ok = 0
    for t = 1, 2000 do if trial(budget) then ok = ok + 1 end end
    line[#line + 1] = string.format("%d ходов — %.1f %%", budget, ok / 20)
  end
  print(string.format("кв. %d «%s» (норма %d, состояний %d): %s", id, def.name, opt, #st, table.concat(line, "; ")))
end
