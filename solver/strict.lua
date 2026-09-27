-- solver/strict.lua — строгие проверки уровня (требование Lao: как в Jelly no Puzzle, наобум не пройти):
--   M.monkey   — точная вероятность пройти наобум: случайный допустимый ход, «смыло» — откат,
--                после 5×нормы ходов без успеха — «Заново»; бюджет по умолчанию 1000 ходов;
--   M.shortest — число разных кратчайших последовательностей ходов и ширина их «коридора».
local R = require("core.rules")
local M = {}

function M.graph(def, cap)
  local lvl = R.compile(def)
  local s0 = R.newState(lvl)
  local ids, st, succ, win, dead, dist, order = { [R.key(s0)] = 1 }, { s0 }, {}, {}, {}, { 0 }, { 1 }
  local head = 1
  while head <= #order do
    local i = order[head]; head = head + 1
    local s = st[i]
    st[i] = nil
    win[i] = (not s.dead) and R.isWin(lvl, s) or false
    dead[i] = s.dead and true or false
    local out = {}
    if not win[i] and not dead[i] then
      for m = 1, 8 do
        local mv = R.MOVES[m]
        local ns = R.move(lvl, s, mv.which, mv.dir)
        if ns then
          local k = R.key(ns)
          local j = ids[k]
          if not j then
            j = #dist + 1
            if cap and j > cap then return nil end
            ids[k], st[j], dist[j] = j, ns, dist[i] + 1
            order[#order + 1] = j
          end
          out[#out + 1] = j
        end
      end
    end
    succ[i] = out
  end
  local opt
  for i = 1, #dist do if win[i] and (not opt or dist[i] < opt) then opt = dist[i] end end
  return { n = #dist, succ = succ, win = win, dead = dead, dist = dist, opt = opt }
end

function M.shortest(G)
  if not G or not G.opt then return nil end
  local cnt = { [1] = 1 }
  for i = 1, G.n do
    local c = cnt[i]
    if c and not G.win[i] and not G.dead[i] then
      for _, j in ipairs(G.succ[i]) do
        if G.dist[j] == G.dist[i] + 1 then cnt[j] = (cnt[j] or 0) + c end
      end
    end
  end
  local total, on = 0, {}
  for i = 1, G.n do if G.win[i] and G.dist[i] == G.opt then total = total + (cnt[i] or 0); on[i] = true end end
  for i = G.n, 1, -1 do
    if not on[i] and not G.win[i] and not G.dead[i] and G.dist[i] < G.opt then
      for _, j in ipairs(G.succ[i]) do
        if on[j] and G.dist[j] == G.dist[i] + 1 then on[i] = true; break end
      end
    end
  end
  local width = {}
  for i = 1, G.n do if on[i] then width[G.dist[i]] = (width[G.dist[i]] or 0) + 1 end end
  local maxw, spread = 1, 0
  for d = 0, G.opt do
    local w = width[d] or 0
    if w > maxw then maxw = w end
    if w > 1 then spread = spread + 1 end
  end
  return { count = total, maxWidth = maxw, spread = spread }
end

function M.monkey(G, budget, restart)
  if not G or not G.opt then return nil end
  budget, restart = budget or 1000, restart or 5
  local T = restart * G.opt
  local p, ok = { [1] = 1.0 }, 0
  for _ = 1, T do
    local np = {}
    for i, pr in pairs(p) do
      local out = G.succ[i]
      local k = #out
      if k > 0 then
        local share = pr / k
        for _, j in ipairs(out) do
          if G.win[j] then ok = ok + share
          elseif G.dead[j] then np[i] = (np[i] or 0) + share
          else np[j] = (np[j] or 0) + share end
        end
      end
    end
    p = np
  end
  return 100 * (1 - (1 - ok) ^ (budget / T)), 100 * ok
end

function M.check(def, cap)
  local G = M.graph(def, cap)
  if not G or not G.opt then return nil end
  local sh = M.shortest(G)
  local mk = M.monkey(G, 1000)
  return { monkey = mk, shortest = sh.count, maxWidth = sh.maxWidth, spread = sh.spread, opt = G.opt, states = G.n }
end
return M
