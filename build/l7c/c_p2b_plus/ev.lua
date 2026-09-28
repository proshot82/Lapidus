-- ev.lua файл.lua [файл2.lua ...] — быстрые ворота кандидата одной строкой (как build/l6b/check.lua, но без
-- абляций и без повторного обхода strict.lua: наобум, число и ширина кратчайших считаются на том же графе).
-- Решений и кадров не печатает. Разметка видимого проигрыша — def.visibleLoss самого файла.
-- Переменная окружения NOSTRICT=1 — пропустить наобум/кратчайшие.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local M = {}

function M.eval(def, opts)
  opts = opts or {}
  local ok, lvl = pcall(R.compile, def)
  if not ok then return { line = "COMPILE: " .. tostring(lvl) } end
  local errs = R.validate(lvl)
  if #errs > 0 then return { line = "ОШИБКИ: " .. table.concat(errs, "; ") } end
  local G = SV.explore(lvl, opts.cap or 3000000)
  if not G then return { line = "CAP" } end
  if not G.firstWin then local n = G.n; SV.freeGraph(G); return { line = "НЕРЕШАЕМ (" .. n .. ")", unsolvable = true, states = n } end
  local good = SV.goodSet(G)
  local function lost(st)
    if not def.washOk then
      for q, p in ipairs(lvl.pieces) do if p.movable and st.pos[q] == 0 then return true end end
    end
    return def.visibleLoss and def.visibleLoss(lvl, st) or false
  end
  local lostF, hidden = {}, {}
  local live, vis, hid, washed, nwin, bad = 0, 0, 0, 0, 0, 0
  for i = 1, G.n do
    if G.flag[i] == 1 then nwin = nwin + 1 end
    if G.flag[i] == 2 then washed = washed + 1 else
      local st = R.decode(lvl, G.keys[i])
      local lf = lost(st); lostF[i] = lf
      if good[i] == 1 then live = live + 1; if lf and G.flag[i] ~= 1 then bad = bad + 1 end
      elseif lf then vis = vis + 1 else hid = hid + 1; hidden[i] = true end
    end
  end
  local opt = G.depth[G.firstWin]
  local E, ES = G.edges.p, G.eStart.p
  -- умная обезьяна (как check.lua)
  local T = 5 * opt
  local p, okp = { [1] = 1.0 }, 0
  for _ = 1, T do
    local np = {}
    for i, pr in pairs(p) do
      local cand = {}
      for e = ES[i - 1], ES[i] - 1 do
        local j = E[e]
        if G.flag[j] == 1 then cand[#cand + 1] = j elseif G.flag[j] ~= 2 and not lostF[j] then cand[#cand + 1] = j end
      end
      if #cand == 0 then np[i] = (np[i] or 0) + pr else
        local share = pr / #cand
        for _, j in ipairs(cand) do if G.flag[j] == 1 then okp = okp + share else np[j] = (np[j] or 0) + share end end
      end
    end
    p = np
  end
  local smart = 100 * (1 - (1 - okp) ^ (1000 / T))
  -- наобум (как solver/strict.lua: смыло — откат, «Заново» после 5×нормы)
  local monkey
  if not os.getenv("NOSTRICT") then
    local p2, ok2 = { [1] = 1.0 }, 0
    for _ = 1, T do
      local np = {}
      for i, pr in pairs(p2) do
        local k = ES[i] - ES[i - 1]
        if k > 0 then
          local share = pr / k
          for e = ES[i - 1], ES[i] - 1 do
            local j = E[e]
            if G.flag[j] == 1 then ok2 = ok2 + share
            elseif G.flag[j] == 2 then np[i] = (np[i] or 0) + share
            else np[j] = (np[j] or 0) + share end
          end
        end
      end
      p2 = np
    end
    monkey = 100 * (1 - (1 - ok2) ^ (1000 / T))
  end
  -- кратчайший путь
  local path, x = {}, G.firstWin
  while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
  table.insert(path, 1, 1)
  -- глубина скрытой ветки у пути
  local function depthFrom(j)
    local d, q, h, maxd = { [j] = 0 }, { j }, 1, 0
    while h <= #q do
      local u = q[h]; h = h + 1
      for e = ES[u - 1], ES[u] - 1 do
        local v = E[e]
        if hidden[v] and d[v] == nil then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; q[#q + 1] = v end
      end
    end
    return maxd, #q
  end
  local deepAt, maxDeep = {}, 0
  for k = 1, #path - 1 do
    local s = path[k]
    for e = ES[s - 1], ES[s] - 1 do
      local j = E[e]
      if hidden[j] then local d = depthFrom(j); if d > (deepAt[k - 1] or -1) then deepAt[k - 1] = d end; if d > maxDeep then maxDeep = d end end
    end
  end
  local dl = {}
  for k = 0, #path - 2 do if deepAt[k] then dl[#dl + 1] = k .. ":" .. deepAt[k] end end
  -- безопасные ходы, прогулка, вынужденные
  local function objs(i) local st = R.decode(lvl, G.keys[i]); local t = {}; for q = 1, #st.pos do t[#t+1] = st.pos[q] .. (st.fixed[q] and "f" or "") end; return table.concat(t, ",") end
  local safeSeq, streak, maxStreak, events, forced, maxForced = {}, 0, 0, 0, 0, 0
  for i = 1, #path - 1 do
    local s, safe = path[i], 0
    for e = ES[s - 1], ES[s] - 1 do if good[E[e]] == 1 then safe = safe + 1 end end
    safeSeq[#safeSeq + 1] = safe
    if safe == 1 then forced = forced + 1; if forced > maxForced then maxForced = forced end else forced = 0 end
    if objs(path[i]) ~= objs(path[i + 1]) then events = events + 1; streak = 0 else streak = streak + 1; if streak > maxStreak then maxStreak = streak end end
  end
  -- число и ширина кратчайших (как strict.lua, по тому же графу)
  local nshort, width
  if not os.getenv("NOSTRICT") then
    local cnt = { [1] = 1 }
    local order = {}
    for i = 1, G.n do order[i] = i end
    -- BFS-порядок по номеру совпадает с глубиной (explore нумерует по слоям)
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
        for e = ES[i - 1], ES[i] - 1 do
          local j = E[e]
          if on[j] and G.depth[j] == G.depth[i] + 1 then on[i] = true; break end
        end
      end
    end
    local w = {}
    for i = 1, G.n do if on[i] then w[G.depth[i]] = (w[G.depth[i]] or 0) + 1 end end
    width = 1
    for d = 0, opt do if (w[d] or 0) > width then width = w[d] end end
    nshort = total
  end
  local n = G.n
  SV.freeGraph(G); require("ffi").C.free(good)
  local r = {
    opt = opt, states = n, live = live, vis = vis, hid = hid, bad = bad, nwin = nwin,
    hiddenPct = 100 * hid / math.max(1, hid + live), smart = smart, deep = maxDeep, deepList = table.concat(dl, " "),
    walk = maxStreak, forced = maxForced, events = events, safe = table.concat(safeSeq, ""), monkey = monkey,
    nshort = nshort, width = width,
  }
  r.line = string.format("ходов %d | сост. %d (живых %d, вид. %d, скр. %d%s) | СКРЫТЫХ %.1f%% | обезьяна %.3f%% | ГЛУБИНА %d [%s] | наобум %s | кратч. %s/ш%s | прогулка %d | вынужд. %d | событий %d | выигрышных %d",
    opt, n, live, vis, hid, bad > 0 and (", ЖИВЫХ ПОМЕЧЕНО " .. bad) or "", r.hiddenPct, smart, maxDeep, r.deepList,
    monkey and string.format("%.3f%%", monkey) or "-", tostring(nshort), tostring(width), maxStreak, maxForced, events, nwin)
  return r
end

if arg and arg[0] and arg[0]:match("ev%.lua$") then
  for _, f in ipairs(arg) do
    local def = dofile(f)
    local r = M.eval(def)
    print((f:match("([^/]+)%.lua$") or f) .. ": " .. r.line)
    io.stdout:flush()
  end
end
return M
