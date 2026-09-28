-- quick.lua — метрики ворот одной функцией (для пакетной доводки вариантов своего ядра).
-- local Q = dofile("build/l6c/b_wall_forever/quick.lua"); local m = Q.metrics(def)
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local Q = {}
function Q.metrics(def, cap)
  local lvl = R.compile(def)
  local errs = R.validate(lvl)
  if #errs > 0 then return { err = table.concat(errs, "; ") } end
  local G = SV.explore(lvl, cap or 2000000)
  if not G then return { err = "CAP" } end
  if not G.firstWin then local n = G.n; SV.freeGraph(G); return { unsolv = true, n = n } end
  local good = SV.goodSet(G)
  local E, ES = G.edges.p, G.eStart.p
  local states = {}
  local function st(i) local s = states[i]; if not s then s = R.decode(lvl, G.keys[i]); states[i] = s end; return s end
  local function lost(s)
    for q, p in ipairs(lvl.pieces) do if p.movable and s.pos[q] == 0 then return true end end
    return def.visibleLoss and def.visibleLoss(lvl, s) or false
  end
  local lostc = {}
  local function L(i) local v = lostc[i]; if v == nil then v = lost(st(i)); lostc[i] = v end; return v end
  local live, vis, hid, falsevis, nwin = 0, 0, 0, 0, 0
  local hidden = {}
  for i = 1, G.n do
    if G.flag[i] == 1 then nwin = nwin + 1 end
    if G.flag[i] ~= 2 then
      if good[i] == 1 then live = live + 1; if L(i) then falsevis = falsevis + 1 end
      elseif L(i) then vis = vis + 1 else hid = hid + 1; hidden[i] = true end
    end
  end
  local opt = G.depth[G.firstWin]
  local T = 5 * opt
  local p, ok = { [1] = 1.0 }, 0
  for _ = 1, T do
    local np = {}
    for i, pr in pairs(p) do
      local cand = {}
      for e = ES[i - 1], ES[i] - 1 do
        local j = E[e]
        if G.flag[j] == 1 then cand[#cand + 1] = j elseif G.flag[j] ~= 2 and not L(j) then cand[#cand + 1] = j end
      end
      if #cand == 0 then np[i] = (np[i] or 0) + pr else
        local share = pr / #cand
        for _, j in ipairs(cand) do if G.flag[j] == 1 then ok = ok + share else np[j] = (np[j] or 0) + share end end
      end
    end
    p = np
  end
  local smart = 100 * (1 - (1 - ok) ^ (1000 / T))
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
  local maxDeep, trapSteps, deepSteps = 0, 0, {}
  for k = 1, #path - 1 do
    local s = path[k]
    local has = false
    for e = ES[s - 1], ES[s] - 1 do
      local j = E[e]
      if hidden[j] then has = true; local d = depthFrom(j); if d > maxDeep then maxDeep = d end; if d >= 8 then deepSteps[#deepSteps+1] = k - 1 end end
    end
    if has then trapSteps = trapSteps + 1 end
  end
  local function objs(i) local s = st(i); local t = {}; for q = 1, #s.pos do t[#t+1] = s.pos[q] .. (s.fixed[q] and "f" or "") end; return table.concat(t, ",") end
  local safeSeq, streak, maxStreak, events = {}, 0, 0, 0
  for i = 1, #path - 1 do
    local s, safe = path[i], 0
    for e = ES[s-1], ES[s]-1 do if good[E[e]] == 1 then safe = safe + 1 end end
    safeSeq[#safeSeq+1] = safe
    if objs(path[i]) ~= objs(path[i+1]) then events = events + 1; streak = 0 else streak = streak + 1; if streak > maxStreak then maxStreak = streak end end
  end
  -- кратчайшие: число и ширина коридора
  local cnt = { [1] = 1 }
  local order = {}
  for i = 1, G.n do order[i] = i end
  -- BFS-порядок = порядок индексов (explore нумерует в порядке BFS)
  for i = 1, G.n do
    local c = cnt[i]
    if c and G.flag[i] == 0 then
      for e = ES[i - 1], ES[i] - 1 do
        local j = E[e]
        if G.depth[j] == G.depth[i] + 1 then cnt[j] = (cnt[j] or 0) + c end
      end
    end
  end
  local total, on = 0, {}
  for i = 1, G.n do if G.flag[i] == 1 and G.depth[i] == opt then total = total + (cnt[i] or 0); on[i] = true end end
  for i = G.n, 1, -1 do
    if not on[i] and G.flag[i] == 0 and G.depth[i] < opt then
      for e = ES[i - 1], ES[i] - 1 do local j = E[e]; if on[j] and G.depth[j] == G.depth[i] + 1 then on[i] = true; break end end
    end
  end
  local width, maxw = {}, 1
  for i = 1, G.n do if on[i] then width[G.depth[i]] = (width[G.depth[i]] or 0) + 1; if width[G.depth[i]] > maxw then maxw = width[G.depth[i]] end end end
  local res = { opt = opt, n = G.n, live = live, vis = vis, hid = hid, falsevis = falsevis, nwin = nwin,
    hidpct = 100 * hid / math.max(1, hid + live), smart = smart, deep = maxDeep, deepSteps = deepSteps,
    walk = maxStreak, events = events, safe = table.concat(safeSeq, ""), trapSteps = trapSteps,
    nshort = total, width = maxw }
  SV.freeGraph(G); require("ffi").C.free(good)
  return res
end
function Q.line(m)
  if m.err then return "ERR " .. m.err end
  if m.unsolv then return "НЕРЕШАЕМ n=" .. m.n end
  return string.format("ходов %d n=%d скр %.0f%% обез %.2f%% глуб %d прог %d соб %d кратч %d/%d вых %d ловушек-шагов %d%s  %s",
    m.opt, m.n, m.hidpct, m.smart, m.deep, m.walk, m.events, m.nshort, m.width, m.nwin, m.trapSteps,
    m.falsevis > 0 and (" ЛОЖНОВИД " .. m.falsevis) or "", m.safe)
end
return Q
