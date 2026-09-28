-- build/l3c/ev.lua — все ворота кандидата кв. 3 разом (по образцу build/l6b/check.lua, 28.09).
-- luajit build/l3c/ev.lua файл.lua [std|own] [vis=файл_с_visibleLoss.lua] [frames]
-- Отличие от check.lua — правило «видимо проиграно»:
--   own (по умолчанию, если в уровне есть def.lost): def.lost(lvl, st) целиком — смытое мыло НЕ считается проигрышем
--       само по себе (в кв. 3 одно мыло по замыслу уходит в слив), решает функция уровня;
--   std: как в check.lua — любая смытая деталь = проигрыш, иначе def.visibleLoss.
--   vis=файл: подменить правило функцией из файла (return function(lvl, st) ... end) — для проверки скептиком.
-- Печатает только метрики; кадры (frames) — только в выводе инструмента, никогда в файлы и ответы.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local ST = require("solver.strict")
local def = dofile(arg[1])
local mode, visFile, frames, ruleName, quick = nil, nil, false, nil, false
for i = 2, #arg do
  local a = arg[i]
  if a == "std" or a == "own" then mode = a
  elseif a:match("^vis=") then visFile = a:sub(5)
  elseif a:match("^rule=") then ruleName = a:sub(6)
  elseif a == "frames" then frames = true
  elseif a == "quick" then quick = true end
end
local lvl = R.compile(def)
local errs, warns = R.validate(lvl)
if #errs > 0 then print("ОШИБКИ: " .. table.concat(errs, "; ")) return end
for _, w in ipairs(warns) do print("warning: " .. w) end
local G = SV.explore(lvl, 3000000)
if not G then print("CAP") return end
local good = SV.goodSet(G)
if not G.firstWin then print(string.format("НЕРЕШАЕМ (состояний %d)", G.n)) return end
local rule
if ruleName then
  local V = dofile("build/l3c/vis.lua")
  local parts = ({ narrow = {}, d = { d = true }, e = { e = true }, wide = { d = true, e = true } })[ruleName]
  rule = V.make(assert(def.step, "нет def.step"), false, parts)
  visFile = "rule=" .. ruleName
elseif visFile then rule = dofile(visFile)
elseif mode ~= "std" and def.lost then rule = def.lost end
local function lost(st)
  if rule then return rule(lvl, st) and true or false end
  for q, p in ipairs(lvl.pieces) do if p.movable and st.pos[q] == 0 then return true end end
  return def.visibleLoss and def.visibleLoss(lvl, st) or false
end
local states, live, vis, hid, washed, nwin, liveMarked = {}, 0, 0, 0, 0, 0, 0
local hidden, lostF = {}, {}
for i = 1, G.n do
  if G.flag[i] == 1 then nwin = nwin + 1 end
  if G.flag[i] == 2 then washed = washed + 1 else
    local st = R.decode(lvl, G.keys[i]); states[i] = st
    lostF[i] = lost(st)
    if good[i] == 1 then live = live + 1; if G.flag[i] ~= 1 and lostF[i] then liveMarked = liveMarked + 1 end
    elseif lostF[i] then vis = vis + 1 else hid = hid + 1; hidden[i] = true end
  end
end
local opt = G.depth[G.firstWin]
local T = 5 * opt
local p, ok = { [1] = 1.0 }, 0
for _ = 1, T do
  local np = {}
  for i, pr in pairs(p) do
    local cand = {}
    for e = G.eStart.p[i - 1], G.eStart.p[i] - 1 do
      local j = G.edges.p[e]
      if G.flag[j] == 1 then cand[#cand + 1] = j elseif G.flag[j] ~= 2 and not lostF[j] then cand[#cand + 1] = j end
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
    for e = G.eStart.p[u - 1], G.eStart.p[u] - 1 do
      local v = G.edges.p[e]
      if hidden[v] and d[v] == nil then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; q[#q + 1] = v end
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
local function objs(i) local st = R.decode(lvl, G.keys[i]); local t = {}; for q = 1, #st.pos do t[#t+1] = st.pos[q] .. (st.fixed[q] and "f" or "") end; return table.concat(t, ",") end
local safeSeq, streak, maxStreak, events = {}, 0, 0, 0
local walks = {}
local forced, maxForced = 0, 0
for i = 1, #path - 1 do
  local s, safe = path[i], 0
  for e = G.eStart.p[s-1], G.eStart.p[s]-1 do if good[G.edges.p[e]] == 1 then safe = safe + 1 end end
  safeSeq[#safeSeq+1] = safe
  if safe == 1 then forced = forced + 1; if forced > maxForced then maxForced = forced end else forced = 0 end
  if objs(path[i]) ~= objs(path[i+1]) then events = events + 1; walks[#walks + 1] = streak; streak = 0 else streak = streak + 1; if streak > maxStreak then maxStreak = streak end end
end
walks[#walks + 1] = streak
local sx = (not quick) and ST.check(def, 3000000) or nil
local tag = visFile and (visFile:match("^rule=") and visFile or ("vis=" .. visFile)) or (rule and "own" or "std")
print(string.format("[%s] ходов %d | состояний %d (живых %d, видимых потерь %d, скрытых %d, смыт %d) | выигрышных %d | живых помечено видимыми %d",
  tag, opt, G.n, live, vis, hid, washed, nwin, liveMarked))
print(string.format("СКРЫТЫХ %.0f %% (≥40) | УМНАЯ ОБЕЗЬЯНА %.2f %% (≤0.2) | ГЛУБИНА %d (≥8) у пути [%s]",
  100 * hid / math.max(1, hid + live), smart, maxDeep, table.concat(dl, " ")))
if sx then print(string.format("строго: наобум %.3f %% (≤1) | кратчайших %d, ширина %d (≤3)", sx.monkey, sx.shortest, sx.maxWidth)) end
print(string.format("событий %d, прогулка max %d (отрезки без событий: %s), вынужденных подряд max %d; безопасных по шагам: %s", events, maxStreak, table.concat(walks, ","), maxForced, table.concat(safeSeq, "")))
local abl = quick and {} or SV.ablations(def, { cap = 3000000 })
local ab = {}
for _, a in ipairs(abl) do ab[#ab + 1] = a.name .. "=" .. (a.solvable == false and "нерешаем" or "РЕШАЕМ") end
if #ab > 0 then print("абляции: " .. table.concat(ab, ", ")) end
if frames then
  local SYM = { source = "S", fixture = "F", stub = "T", pipe = "=", fitting = "b", porcelain = "P" }
  local function show(s, label)
    local rows = {}
    for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x]; rows[y][x] = c == 1 and "#" or (c == 2 and "~" or ".") end end
    for q, pp in ipairs(lvl.pieces) do if s.pos[q] ~= 0 then local x, y = R.xy(lvl, s.pos[q]); local ch = SYM[pp.kind]; if pp.movable then ch = s.fixed[q] and ch:upper() or ch:lower() end; rows[y][x] = ch end end
    if not s.dead then for i, c in ipairs(s.body) do local x, y = R.xy(lvl, c); rows[y][x] = (i == #s.body) and "H" or ((i == 1) and "f" or "o") end end
    local out = { label }
    for y = 1, lvl.H do out[#out+1] = table.concat(rows[y]) end
    return out
  end
  local fr = {}
  for i, id in ipairs(path) do
    local st = R.decode(lvl, G.keys[id])
    local lab = (i == 1) and "start" or ((i-1) .. R.moveName(G.pmove[id]):gsub("heel", "f"):gsub("head", "H"):gsub(":", ""):sub(1, 3))
    fr[#fr+1] = show(st, lab .. (good[id] == 1 and "" or "!"))
  end
  local per = math.max(1, math.floor(110 / (lvl.W + 2)))
  for k = 1, #fr, per do
    for line = 1, #fr[k] do
      local parts = {}
      for j = k, math.min(k + per - 1, #fr) do parts[#parts+1] = string.format("%-" .. (lvl.W + 2) .. "s", fr[j][line] or "") end
      print(table.concat(parts, ""))
    end
    print()
  end
end
SV.freeGraph(G); require("ffi").C.free(good)
