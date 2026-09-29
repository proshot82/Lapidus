-- build/l1c/an.lua — разбор кандидата кв. 1 (уровень без деталей: только Лапидус, крюк, стояк, прибор, сливы).
-- luajit build/l1c/an.lua файл.lua [frames] [heat]
-- Классы мёртвых состояний (не смытых):
--   O («не той стороной»): выиграть нельзя, а Лапидусом, перевёрнутым концами (то же тело, голова ↔ ноги), — можно;
--   P (позиционный): нельзя ни так, ни перевёрнутым.
-- Разметки видимого проигрыша:
--   file   — def.visibleLoss из файла (основная, мерка новичка);
--   flip   — видимо, если класс P (так и перевёрнутым — нельзя): «яма без выхода»;
--   reach  — узкая: видимо, если ни так, ни перевёрнутым не добраться даже до клеток финальной сборки;
--   expert — «знаток»: видимо всё, что противоречит финальной сборке (класс O и P) и проигрыш, вскрывающийся
--            следующим ходом (все ходы — в смыв или в видимое по flip).
-- События (для уровня без деталей): прикручивание/откручивание конца или падение Лапидуса.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local ST = require("solver.strict")
local file = arg[1]
local OPT = {}
for i = 2, #arg do OPT[arg[i]] = true end
local def = dofile(file)
local lvl = R.compile(def)
local errs, warns = R.validate(lvl)
if #errs > 0 then print("ОШИБКИ: " .. table.concat(errs, "; ")) return end
for _, w in ipairs(warns) do if w ~= "initial layout is not at rest" then print("warning: " .. w) end end
local G = SV.explore(lvl, 3000000)
if not G then print("CAP") return end
local good = SV.goodSet(G)
if not G.firstWin then print(string.format("НЕРЕШАЕМ (состояний %d)", G.n)) SV.freeGraph(G) return end

-- ---------------------------------------------------------------- замыкание по переворотам
local function flipState(st)
  local s = R.clone(st)
  local b, n = s.body, #s.body
  for i = 1, math.floor(n / 2) do b[i], b[n + 1 - i] = b[n + 1 - i], b[i] end
  R.settle(lvl, s)
  return s
end
local idx2, keys2, succ2, win2 = {}, {}, {}, {}
local function add2(k) local i = idx2[k]; if not i then i = #keys2 + 1; keys2[i] = k; idx2[k] = i end; return i end
add2(R.key(R.newState(lvl)))
local h = 1
while h <= #keys2 do
  local st = R.decode(lvl, keys2[h])
  local out = {}
  if not st.dead then
    if R.isWin(lvl, st) then win2[h] = true else
      for m = 1, 8 do
        local mm = R.MOVES[m]
        local ns = R.move(lvl, st, mm.which, mm.dir)
        if ns then out[#out + 1] = add2(R.key(ns)) end
      end
    end
    add2(R.key(flipState(st)))
  end
  succ2[h] = out
  h = h + 1
end
local function backReach(targets)
  local rev = {}
  for i = 1, #keys2 do for _, j in ipairs(succ2[i]) do rev[j] = rev[j] or {}; table.insert(rev[j], i) end end
  local ok, q, hh = {}, {}, 1
  for i in pairs(targets) do ok[i] = true; q[#q + 1] = i end
  while hh <= #q do local j = q[hh]; hh = hh + 1; for _, i in ipairs(rev[j] or {}) do if not ok[i] then ok[i] = true; q[#q + 1] = i end end end
  return ok
end
local good2 = backReach(win2)
-- клетки финальной сборки
local winSet = {}
for i = 1, G.n do if G.flag[i] == 1 then local st = R.decode(lvl, G.keys[i]); local t = {}; for _, c in ipairs(st.body) do t[#t + 1] = c end; table.sort(t); winSet[table.concat(t, ",")] = true end end
local posT = {}
for i = 1, #keys2 do
  local st = R.decode(lvl, keys2[i])
  if not st.dead then local t = {}; for _, c in ipairs(st.body) do t[#t + 1] = c end; table.sort(t); if winSet[table.concat(t, ",")] then posT[i] = true end end
end
local reachPos = backReach(posT)

local states, cls = {}, {}
local cnt = { live = 0, O = 0, P = 0, washed = 0 }
local flipIdx = {}
for i = 1, G.n do
  if G.flag[i] == 2 then cnt.washed = cnt.washed + 1 else
    local st = R.decode(lvl, G.keys[i]); states[i] = st
    local fi = idx2[R.key(flipState(st))]; flipIdx[i] = fi
    if good[i] == 1 then cls[i] = "live"
    elseif good2[fi] then cls[i] = "O"
    else cls[i] = "P" end
    cnt[cls[i]] = cnt[cls[i]] + 1
  end
end
local function visFile(i) return def.visibleLoss and def.visibleLoss(lvl, states[i]) or false end
local function visFlip(i) return cls[i] == "P" end
local function visReach(i)
  if cls[i] == "live" then return false end
  local k = idx2[G.keys[i]]
  return not (reachPos[k] or reachPos[flipIdx[i]])
end
local function visExpert(i)
  if cls[i] ~= "live" then return true end
  return false
end
local measures = { { "file", visFile }, { "flip", visFlip }, { "reach", visReach }, { "expert", visExpert } }

local opt = G.depth[G.firstWin]
local T = 5 * opt
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)

local function evalMeasure(vis)
  local live, v, hid = 0, 0, 0
  local hidden = {}
  for i = 1, G.n do
    if G.flag[i] ~= 2 then
      if good[i] == 1 then live = live + 1 elseif vis(i) then v = v + 1 else hid = hid + 1; hidden[i] = true end
    end
  end
  -- умная обезьяна
  local p, ok = { [1] = 1.0 }, 0
  for _ = 1, T do
    local np = {}
    for i, pr in pairs(p) do
      local cand = {}
      for e = G.eStart.p[i - 1], G.eStart.p[i] - 1 do
        local j = G.edges.p[e]
        if G.flag[j] == 1 then cand[#cand + 1] = j elseif G.flag[j] ~= 2 and not vis(j) then cand[#cand + 1] = j end
      end
      if #cand == 0 then np[i] = (np[i] or 0) + pr else
        local share = pr / #cand
        for _, j in ipairs(cand) do if G.flag[j] == 1 then ok = ok + share else np[j] = (np[j] or 0) + share end end
      end
    end
    p = np
  end
  local smart = 100 * (1 - (1 - ok) ^ (1000 / T))
  local function depthFrom(j)
    local d, q, hh, maxd = { [j] = 0 }, { j }, 1, 0
    while hh <= #q do
      local u = q[hh]; hh = hh + 1
      for e = G.eStart.p[u - 1], G.eStart.p[u] - 1 do
        local w = G.edges.p[e]
        if hidden[w] and d[w] == nil then d[w] = d[u] + 1; if d[w] > maxd then maxd = d[w] end; q[#q + 1] = w end
      end
    end
    return maxd
  end
  local deepAt, maxDeep = {}, 0
  for k = 1, #path - 1 do
    local s = path[k]
    for e = G.eStart.p[s - 1], G.eStart.p[s] - 1 do
      local j = G.edges.p[e]
      if hidden[j] then local d = depthFrom(j); if d > (deepAt[k - 1] or -1) then deepAt[k - 1] = d end; if d > maxDeep then maxDeep = d end end
    end
  end
  local dl = {}
  for k = 0, #path - 2 do if deepAt[k] then dl[#dl + 1] = k .. ":" .. deepAt[k] end end
  return { live = live, vis = v, hid = hid, pct = 100 * hid / math.max(1, hid + live), smart = smart, deep = maxDeep, dl = table.concat(dl, " ") }
end

-- события и прогулки вдоль кратчайшего пути
local function screws(st)
  local piece = R.occupancy(st)
  return tostring(R.endScrew(lvl, st, piece, "head")) .. "/" .. tostring(R.endScrew(lvl, st, piece, "heel"))
end
local events, streak, maxWalk, walks = 0, 0, 0, {}
local forcedRun, maxForced, safeSeq = 0, 0, {}
for k = 1, #path - 1 do
  local a, b = R.decode(lvl, G.keys[path[k]]), R.decode(lvl, G.keys[path[k + 1]])
  local m = G.pmove[path[k + 1]]
  local tr = {}
  R.move(lvl, a, R.MOVES[m].which, R.MOVES[m].dir, tr)
  local fell = false
  for _, t in ipairs(tr) do if t.kind == "settle" then fell = true end end
  local ev = fell or (screws(a) ~= screws(b))
  if ev then events = events + 1; walks[#walks + 1] = streak; streak = 0 else streak = streak + 1; if streak > maxWalk then maxWalk = streak end end
  local s, safe = path[k], 0
  for e = G.eStart.p[s - 1], G.eStart.p[s] - 1 do if good[G.edges.p[e]] == 1 then safe = safe + 1 end end
  safeSeq[#safeSeq + 1] = safe
  if safe == 1 then forcedRun = forcedRun + 1; if forcedRun > maxForced then maxForced = forcedRun end else forcedRun = 0 end
end
walks[#walks + 1] = streak

local nwin = 0
for i = 1, G.n do if G.flag[i] == 1 then nwin = nwin + 1 end end
local sx = ST.check(def, 3000000)
print(string.format("%s: ходов %d | состояний %d (живых %d, O %d, P %d, смыт %d) | выигрышных %d",
  file:match("[^/]+$"), opt, G.n, cnt.live, cnt.O, cnt.P, cnt.washed, nwin))
for _, M in ipairs(measures) do
  if M[1] ~= "file" or def.visibleLoss then
    local r = evalMeasure(M[2])
    print(string.format("  [%-6s] видимых %4d скрытых %4d → СКРЫТЫХ %3.0f %% | обезьяна %.3f %% | глубина %d [%s]",
      M[1], r.vis, r.hid, r.pct, r.smart, r.deep, r.dl))
  end
end
if sx then print(string.format("  строго: наобум %.3f %% | кратчайших %d, ширина %d", sx.monkey, sx.shortest, sx.maxWidth)) end
print(string.format("  событий %d, прогулки %s (max %d); вынужденных подряд max %d; безопасных по шагам: %s",
  events, table.concat(walks, ","), maxWalk, maxForced, table.concat(safeSeq, "")))
if OPT.abl or OPT.all then
  local abl = SV.ablations(def, { cap = 3000000 })
  local ab = {}
  for _, a in ipairs(abl) do ab[#ab + 1] = a.name .. "=" .. (a.solvable == false and "нерешаем" or "РЕШАЕМ") end
  if #ab > 0 then print("  абляции: " .. table.concat(ab, ", ")) end
end

local function blank()
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for xx = 1, lvl.W do local c = lvl.cell[(y - 1) * lvl.W + xx]; rows[y][xx] = c == 1 and "#" or (c == 2 and "~" or ".") end end
  for q, pp in ipairs(lvl.pieces) do local xx, y = R.xy(lvl, pp.start); rows[y][xx] = ({ source = "S", fixture = "F", stub = "T" })[pp.kind] or "?" end
  return rows
end
if OPT.heat then
  -- где голова и ноги в тупиках класса O и P (плотность, без решения)
  for _, C in ipairs({ "O", "P", "live" }) do
    local hc, fc = {}, {}
    for i = 1, G.n do if cls[i] == C then local st = states[i]; local b = st.body; hc[b[#b]] = (hc[b[#b]] or 0) + 1; fc[b[1]] = (fc[b[1]] or 0) + 1 end end
    local rh, rf = blank(), blank()
    local function sym(n) if not n then return nil end; if n < 10 then return tostring(n) end; return string.char(55 + math.min(35, math.floor(n / 10) + 9)) end
    for c, n in pairs(hc) do local xx, y = R.xy(lvl, c); rh[y][xx] = sym(n) end
    for c, n in pairs(fc) do local xx, y = R.xy(lvl, c); rf[y][xx] = sym(n) end
    print("класс " .. C .. ": голова | ноги")
    for y = 1, lvl.H do print("  " .. table.concat(rh[y]) .. "   " .. table.concat(rf[y])) end
  end
end
if OPT.frames then
  local function show(s, label)
    local rows = blank()
    if not s.dead then for i, c in ipairs(s.body) do local xx, y = R.xy(lvl, c); rows[y][xx] = (i == #s.body) and "H" or ((i == 1) and "f" or "o") end end
    local out = { label }
    for y = 1, lvl.H do out[#out + 1] = table.concat(rows[y]) end
    return out
  end
  local frames = {}
  for i, id in ipairs(path) do
    local st = R.decode(lvl, G.keys[id])
    local lab = (i == 1) and "start" or ((i - 1) .. R.moveName(G.pmove[id]):gsub("heel", "f"):gsub("head", "H"):gsub(":", ""):sub(1, 3))
    frames[#frames + 1] = show(st, lab .. (good[id] == 1 and "" or "!"))
  end
  local per = math.max(1, math.floor(120 / (lvl.W + 2)))
  for k = 1, #frames, per do
    for line = 1, #frames[k] do
      local parts = {}
      for j = k, math.min(k + per - 1, #frames) do parts[#parts + 1] = string.format("%-" .. (lvl.W + 2) .. "s", frames[j][line] or "") end
      print(table.concat(parts, ""))
    end
    print()
  end
end
SV.freeGraph(G); require("ffi").C.free(good)
