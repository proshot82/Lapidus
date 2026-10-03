-- build/p6/neck/lib.lua — быстрая оценка кандидата раунда «шея»: метрики §7 + подпись темы
-- «правильные детали, неправильный Лапидус» (RPWL: все нужные детали закреплены на финальных местах, а выиграть нельзя).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local M = {}

function M.eval(def, cap, quiet)
  local okc, lvl = pcall(R.compile, def)
  if not okc then return { err = tostring(lvl) } end
  local errs = R.validate(lvl)
  if #errs > 0 then return { err = table.concat(errs, ";") } end
  local G = SV.explore(lvl, cap or 400000)
  if not G then return { cap = true } end
  if not G.firstWin then local n = G.n; SV.freeGraph(G); return { unsolvable = true, n = n } end
  local good = SV.goodSet(G)
  local VL = V.compute(lvl, G, def, good)
  local n, ES, E, flag = G.n, G.eStart.p, G.edges.p, G.flag
  local win = VL.win
  local rp, hidden = {}, {}
  local live, vis, hid, nrp, nwin = 0, 0, 0, 0, 0
  for i = 1, n do
    if flag[i] == 1 then nwin = nwin + 1 end
    if flag[i] ~= 2 then
      if good[i] == 1 then live = live + 1
      else
        if VL.newbie[i] then vis = vis + 1 else hid = hid + 1; hidden[i] = true end
        local st = VL.states[i]
        local all = true
        for _, q in ipairs(VL.needed) do
          if st.pos[q] ~= win.pos[q] or st.fixed[q] ~= win.fixed[q] then all = false break end
        end
        if all then rp[i] = true; nrp = nrp + 1 end
      end
    end
  end
  local opt = G.depth[G.firstWin]
  local T = 5 * opt
  local p, ok, intoRP, intoDead = { [1] = 1.0 }, 0, 0, 0
  for _ = 1, T do
    local np = {}
    for i, pr in pairs(p) do
      local cand = {}
      for e = ES[i - 1], ES[i] - 1 do
        local j = E[e]
        if flag[j] == 1 then cand[#cand + 1] = j elseif flag[j] ~= 2 and not VL.newbie[j] then cand[#cand + 1] = j end
      end
      if #cand == 0 then np[i] = (np[i] or 0) + pr else
        local share = pr / #cand
        for _, j in ipairs(cand) do
          if flag[j] == 1 then ok = ok + share else
            if good[i] == 1 and good[j] ~= 1 then intoDead = intoDead + share; if rp[j] then intoRP = intoRP + share end end
            np[j] = (np[j] or 0) + share
          end
        end
      end
    end
    p = np
  end
  local smart = 100 * (1 - (1 - ok) ^ (1000 / T))
  -- путь и двери в RPWL / скрытые
  local path, x = {}, G.firstWin
  while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
  table.insert(path, 1, 1)
  local function depthFrom(j)
    local d, q, h, maxd = { [j] = 0 }, { j }, 1, 0
    while h <= #q do
      local u = q[h]; h = h + 1
      for e = ES[u - 1], ES[u] - 1 do
        local v = E[e]
        if hidden[v] and d[v] == nil then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; q[#q + 1] = v end
      end
    end
    return maxd
  end
  local doors, rpdoors, maxDeep = {}, {}, 0
  for k = 1, #path - 1 do
    local s, best, isrp = path[k], -1, false
    for e = ES[s - 1], ES[s] - 1 do
      local j = E[e]
      if hidden[j] then local d = depthFrom(j); if d > best then best = d end; if d > maxDeep then maxDeep = d end end
    end
    if best >= 0 then doors[#doors + 1] = (k - 1) .. ":" .. best end
  end
  -- RPWL достижимо ли «естественно»: глубина входа (в ходах от старта) и сколько скрытых RPWL
  local rphid, rpmin = 0, nil
  for i in pairs(rp) do if hidden[i] then rphid = rphid + 1 end; if not rpmin or G.depth[i] < rpmin then rpmin = G.depth[i] end end
  local res = { opt = opt, n = n, live = live, vis = vis, hid = hid, hidPct = 100 * hid / math.max(1, hid + live),
    smart = smart, nwin = nwin, nrp = nrp, rphid = rphid, rpmin = rpmin, intoRP = 100 * intoRP, intoDead = 100 * intoDead,
    doors = table.concat(doors, " "), maxDeep = maxDeep, ok = 100 * ok }
  SV.freeGraph(G); require("ffi").C.free(good)
  return res
end

function M.line(r)
  if r.err then return "ERR " .. r.err end
  if r.cap then return "CAP" end
  if r.unsolvable then return "НЕРЕШАЕМ n=" .. r.n end
  return string.format("ходов %d n=%d скрытых %.0f%% обезьяна %.2f%% (1 попытка %.2f%%) побед %d | RPWL %d (скрытых %d, с хода %s) | в тупик %.0f%%, из них в RPWL %.0f%% | глуб %d двери [%s]",
    r.opt, r.n, r.hidPct, r.smart, r.ok, r.nwin, r.nrp, r.rphid, tostring(r.rpmin), r.intoDead, r.intoRP, r.maxDeep, r.doors)
end

if arg and arg[0] and arg[0]:match("lib%.lua$") then
  for i = 1, #arg do
    local def = dofile(arg[i])
    print(arg[i] .. ": " .. M.line(M.eval(def, 3000000)))
  end
end
return M
