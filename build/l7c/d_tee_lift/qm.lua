-- qm.lua файл.lua [режим разметки] — быстрые метрики кандидата (без строгих ворот и абляций; без решений и кадров).
-- Режим: имя из def.visModes (по умолчанию def.visibleLoss). Формулы — как в build/l6b/check.lua.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local mode = arg[2]
local vis = def.visibleLoss
if mode and mode ~= "-" then vis = assert(def.visModes and def.visModes[mode], "нет режима " .. mode) end
local lvl = R.compile(def)
local errs = R.validate(lvl)
if #errs > 0 then print("ОШИБКИ: " .. table.concat(errs, "; ")) return end
local G = SV.explore(lvl, 3000000)
if not G then print("CAP") return end
if not G.firstWin then print(string.format("%s: НЕРЕШАЕМ (состояний %d)", arg[1]:match("([^/]+)$"), G.n)) SV.freeGraph(G) return end
local good = SV.goodSet(G)
local function lost(st)
  if not def.washOk then for q, p in ipairs(lvl.pieces) do if p.movable and st.pos[q] == 0 then return true end end end
  return vis and vis(lvl, st) or false
end
local states, live, nvis, hid, washed, nwin, liveVis = {}, 0, 0, 0, 0, 0, 0
local hidden, lostc = {}, {}
for i = 1, G.n do
  if G.flag[i] == 1 then nwin = nwin + 1 end
  if G.flag[i] == 2 then washed = washed + 1 else
    local st = R.decode(lvl, G.keys[i])
    local l = lost(st); lostc[i] = l
    if good[i] == 1 then live = live + 1; if l then liveVis = liveVis + 1 end elseif l then nvis = nvis + 1 else hid = hid + 1; hidden[i] = true end
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
      if G.flag[j] == 1 then cand[#cand + 1] = j elseif G.flag[j] ~= 2 and not lostc[j] then cand[#cand + 1] = j end
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
local safeSeq, streak, maxStreak, events, forced, maxForced = {}, 0, 0, 0, 0, 0
for i = 1, #path - 1 do
  local s, safe = path[i], 0
  for e = G.eStart.p[s-1], G.eStart.p[s]-1 do if good[G.edges.p[e]] == 1 then safe = safe + 1 end end
  safeSeq[#safeSeq+1] = safe
  if safe <= 1 then forced = forced + 1; if forced > maxForced then maxForced = forced end else forced = 0 end
  if objs(path[i]) ~= objs(path[i+1]) then events = events + 1; streak = 0 else streak = streak + 1; if streak > maxStreak then maxStreak = streak end end
end
-- ширина коридора кратчайших
local n = G.n
local E, ES = G.edges.p, G.eStart.p
local rev = {}
for i = 1, n do for e = ES[i - 1], ES[i] - 1 do local j = E[e]; local t = rev[j]; if not t then t = {}; rev[j] = t end; t[#t + 1] = i end end
local dw, q, h = {}, {}, 1
for i = 1, n do if G.flag[i] == 1 then dw[i] = 0; q[#q + 1] = i end end
while h <= #q do local u = q[h]; h = h + 1; for _, pp in ipairs(rev[u] or {}) do if dw[pp] == nil and G.flag[pp] ~= 2 then dw[pp] = dw[u] + 1; q[#q + 1] = pp end end end
local w = {}
for i = 1, n do if dw[i] and G.depth[i] + dw[i] == opt then w[G.depth[i]] = (w[G.depth[i]] or 0) + 1 end end
local maxw = 0
for d = 0, opt do if (w[d] or 0) > maxw then maxw = w[d] end end
print(string.format("%s%s: ходов %d | сост. %d (живых %d, вид. %d, скрытых %d, смыт %d) | выигрышных %d | СКРЫТЫХ %.1f %% | обезьяна %.3f %% | глубина %d [%s] | прогулка %d | вынужд. %d | ширина %d | событий %d%s",
  arg[1]:match("([^/]+)$"), mode and ("[" .. mode .. "]") or "", opt, G.n, live, nvis, hid, washed, nwin, 100 * hid / math.max(1, hid + live), smart, maxDeep, table.concat(dl, " "),
  maxStreak, maxForced, maxw, events, liveVis > 0 and (" | !!! ЖИВЫХ ПОМЕЧЕНО " .. liveVis) or ""))
print("   безопасных по шагам: " .. table.concat(safeSeq, ""))
SV.freeGraph(G); require("ffi").C.free(good)
