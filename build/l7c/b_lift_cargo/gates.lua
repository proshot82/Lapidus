-- gates.lua — те же ворота, что build/l6b/check.lua, функцией (копия из build/l6c/e_orientation, коридор кв. 7: 20–45 ходов).
-- local GT = dofile("build/l6c/c_stub_ladder/gates.lua"); local r = GT.eval(def) → r.line, r.fails
-- Решений не печатает.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local ST = require("solver.strict")
local M = {}

function M.eval(def, opts)
  opts = opts or {}
  local ok, lvl = pcall(R.compile, def)
  if not ok then return { line = "COMPILE: " .. tostring(lvl), fails = { "compile" } } end
  local errs = R.validate(lvl)
  if #errs > 0 then return { line = "ОШИБКИ: " .. table.concat(errs, "; "), fails = { "invalid" } } end
  local G = SV.explore(lvl, opts.cap or 3000000)
  if not G then return { line = "CAP", fails = { "cap" } } end
  if not G.firstWin then local n = G.n; SV.freeGraph(G); return { line = "НЕРЕШАЕМ (" .. n .. ")", fails = { "unsolvable" }, unsolvable = true } end
  local good = SV.goodSet(G)
  local function lost(st)
    for q, p in ipairs(lvl.pieces) do if p.movable and st.pos[q] == 0 then return true end end
    return def.visibleLoss and def.visibleLoss(lvl, st) or false
  end
  local states, live, vis, hid, washed, nwin = {}, 0, 0, 0, 0, 0
  local hidden = {}
  local winCfg = {}
  local function cfgKey(st)
    local t = {}
    for q, p in ipairs(lvl.pieces) do if p.movable then t[#t+1] = st.pos[q] .. (st.fixed[q] and "f" or "") end end
    return table.concat(t, ",")
  end
  for i = 1, G.n do
    if G.flag[i] == 1 then nwin = nwin + 1; winCfg[cfgKey(R.decode(lvl, G.keys[i]))] = true end
    if G.flag[i] == 2 then washed = washed + 1 else
      local st = R.decode(lvl, G.keys[i]); states[i] = st
      if good[i] == 1 then live = live + 1 elseif lost(st) then vis = vis + 1 else hid = hid + 1; hidden[i] = true end
    end
  end
  local nWinCfg = 0; for _ in pairs(winCfg) do nWinCfg = nWinCfg + 1 end
  local opt = G.depth[G.firstWin]
  local T = 5 * opt
  local p, okp = { [1] = 1.0 }, 0
  for _ = 1, T do
    local np = {}
    for i, pr in pairs(p) do
      local cand = {}
      for e = G.eStart.p[i - 1], G.eStart.p[i] - 1 do
        local j = G.edges.p[e]
        if G.flag[j] == 1 then cand[#cand + 1] = j elseif G.flag[j] ~= 2 and not lost(states[j]) then cand[#cand + 1] = j end
      end
      if #cand == 0 then np[i] = (np[i] or 0) + pr else
        local share = pr / #cand
        for _, j in ipairs(cand) do if G.flag[j] == 1 then okp = okp + share else np[j] = (np[j] or 0) + share end end
      end
    end
    p = np
  end
  local smart = 100 * (1 - (1 - okp) ^ (1000 / T))
  local path, x = {}, G.firstWin
  while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
  table.insert(path, 1, 1)
  local function depthFrom(j)
    local d, q, h, maxd = { [j] = 0 }, { j }, 1, 0
    while h <= #q do
      local u = q[h]; h = h + 1
      for e = G.eStart.p[u - 1], G.eStart.p[u] - 1 do
        local v = G.edges.p[e]
        if hidden[v] and d[v] == nil then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; q[#q + 1] = v end
      end
    end
    return maxd
  end
  local maxDeep, deepList = 0, {}
  for k = 1, #path - 1 do
    local s = path[k]
    local best = -1
    for e = G.eStart.p[s - 1], G.eStart.p[s] - 1 do
      local j = G.edges.p[e]
      if hidden[j] then local d = depthFrom(j); if d > best then best = d end end
    end
    if best >= 0 then deepList[#deepList + 1] = (k - 1) .. ":" .. best; if best > maxDeep then maxDeep = best end end
  end
  local function objs(i) local st = R.decode(lvl, G.keys[i]); local t = {}; for q = 1, #st.pos do t[#t+1] = st.pos[q] .. (st.fixed[q] and "f" or "") end; return table.concat(t, ",") end
  local safeSeq, streak, maxStreak, events = {}, 0, 0, 0
  local forced, maxForced = 0, 0
  for i = 1, #path - 1 do
    local s, safe = path[i], 0
    for e = G.eStart.p[s-1], G.eStart.p[s]-1 do if good[G.edges.p[e]] == 1 then safe = safe + 1 end end
    safeSeq[#safeSeq+1] = safe
    if safe == 1 then forced = forced + 1; if forced > maxForced then maxForced = forced end else forced = 0 end
    if objs(path[i]) ~= objs(path[i+1]) then events = events + 1; streak = 0 else streak = streak + 1; if streak > maxStreak then maxStreak = streak end end
  end
  local n = G.n
  SV.freeGraph(G); require("ffi").C.free(good)
  local sx = (not opts.nostrict) and ST.check(def, 3000000) or nil
  local abl = {}
  if not opts.noabl then
    for _, a in ipairs(SV.ablations(def, { cap = 3000000 })) do abl[#abl + 1] = a.name .. "=" .. (a.solvable == false and "нерешаем" or "РЕШАЕМ") end
  end
  local r = {
    opt = opt, states = n, live = live, vis = vis, hid = hid, washed = washed, nwin = nwin, nWinCfg = nWinCfg,
    hiddenPct = 100 * hid / math.max(1, hid + live), smart = smart, deep = maxDeep, deepList = table.concat(deepList, " "),
    events = events, walk = maxStreak, forced = maxForced, safe = table.concat(safeSeq, ""),
    monkey = sx and sx.monkey, shortest = sx and sx.shortest, width = sx and sx.maxWidth, abl = table.concat(abl, ", "),
  }
  local f = {}
  if r.monkey and r.monkey > 1 then f[#f+1] = "наобум" end
  if r.width and r.width > 3 then f[#f+1] = "ширина" end
  if r.hiddenPct < 40 then f[#f+1] = "скрытые" end
  if r.smart > 0.2 then f[#f+1] = "обезьяна" end
  if r.deep < 8 then f[#f+1] = "глубина" end
  if r.walk > 6 then f[#f+1] = "прогулка" end
  if r.forced > 4 then f[#f+1] = "вынужденные" end
  if r.nWinCfg ~= 1 then f[#f+1] = "выигрышных" end
  if opt < 20 or opt > 45 then f[#f+1] = "коридор" end
  if events < 3 then f[#f+1] = "события" end
  if r.smart > 0.1 then r.smartNote = "обезьяна>0.1" end
  for _, a in ipairs(abl) do if a:match("РЕШАЕМ") then f[#f+1] = "абляция" break end end
  r.fails = f
  r.line = string.format("ходов %d | сост. %d | скрытых %.0f%% | обезьяна %.2f%% | глубина %d | наобум %s | кратч. %s/ш%s | прогулка %d | вынужд. %d | событий %d | вкфг %d%s",
    opt, n, r.hiddenPct, smart, maxDeep, r.monkey and string.format("%.3f%%", r.monkey) or "-", tostring(r.shortest), tostring(r.width),
    maxStreak, maxForced, events, nWinCfg, (#abl > 0) and (" | абл: " .. r.abl) or "")
  return r
end

return M
