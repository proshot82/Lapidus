-- verify_gates.lua файл.lua [разметка ...] — скептик кв. 7 (28.09): ворота, зависящие от видимого проигрыша,
-- сразу для нескольких разметок из verify_vis.lua на одном графе (строгие ворота от разметки не зависят — их
-- считает check.lua). Для каждой: живых помечено (должно быть 0), скрытых %, умная обезьяна (как в check.lua),
-- глубина скрытой ветки у кратчайшего пути, и ошибки «против подсказки №1» (переходы из живых: скрытые / видимые).
-- Печатает только числа (без ходов и кадров).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = dofile("build/l7c/a_lift_last/verify_vis.lua")
local def = dofile(arg[1])
local lvl = R.compile(def)
local names = {}
for i = 2, #arg do names[#names + 1] = arg[i] end
if #names == 0 then names = { "narrow", "wideA", "V1", "V2", "V3", "V2noCap", "narrowPlus" } end
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local Q = {}
for q, p in ipairs(lvl.pieces) do if p.tag then Q[p.tag] = q end end
local S = {}
local function st(i) if not S[i] then S[i] = R.decode(lvl, G.keys[i]) end return S[i] end
local opt = G.depth[G.firstWin]
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
local I = function(xx, yy) return R.idx(lvl, xx, yy) end
local function col6low(c) if c == 0 then return false end local xx, yy = R.xy(lvl, c); return xx == 6 and yy >= 5 end
local ERR = {
  { "E1 фонтан заглушён раньше переходника", function(a, b) return not a.fixed[Q.elb] and b.fixed[Q.elb] and not b.fixed[Q.adp] end },
  { "E2 заглушён после переходника, муфта ещё не в шахте", function(a, b) return not a.fixed[Q.elb] and b.fixed[Q.elb] and b.fixed[Q.adp] and not col6low(b.pos[Q.cpl]) end },
  { "E3 муфта скормлена фонтану раньше переходника", function(a, b) return not col6low(a.pos[Q.cpl]) and col6low(b.pos[Q.cpl]) and not b.fixed[Q.adp] and not b.fixed[Q.cpl] end },
  { "E4 муфта вкручена (в ванну)", function(a, b) return not a.fixed[Q.cpl] and b.fixed[Q.cpl] end },
  { "E5 муфта отложена в угол кармана", function(a, b) return a.pos[Q.cpl] ~= I(8, 6) and b.pos[Q.cpl] == I(8, 6) end },
}
local onPath = {}
for k, id in ipairs(path) do onPath[id] = k - 1 end
for _, nm in ipairs(names) do
  local vis = assert(V[nm], "нет разметки " .. nm)
  local L = {}
  local function lost(i)
    local v = L[i]
    if v == nil then
      local s = st(i)
      v = false
      for q, p in ipairs(lvl.pieces) do if p.movable and s.pos[q] == 0 then v = true end end
      if not v then v = vis(lvl, s) and true or false end
      L[i] = v
    end
    return v
  end
  local live, nvis, hid, bad = 0, 0, 0, 0
  local hidden = {}
  for i = 1, G.n do
    if G.flag[i] ~= 2 then
      if good[i] == 1 then live = live + 1; if G.flag[i] ~= 1 and lost(i) then bad = bad + 1 end
      elseif lost(i) then nvis = nvis + 1 else hid = hid + 1; hidden[i] = true end
    end
  end
  -- умная обезьяна (как check.lua)
  local T = 5 * opt
  local p, ok = { [1] = 1.0 }, 0
  for _ = 1, T do
    local np = {}
    for i, pr in pairs(p) do
      local cand = {}
      for e = G.eStart.p[i - 1], G.eStart.p[i] - 1 do
        local j = G.edges.p[e]
        if G.flag[j] == 1 then cand[#cand + 1] = j elseif G.flag[j] ~= 2 and not lost(j) then cand[#cand + 1] = j end
      end
      if #cand == 0 then np[i] = (np[i] or 0) + pr else
        local share = pr / #cand
        for _, j in ipairs(cand) do if G.flag[j] == 1 then ok = ok + share else np[j] = (np[j] or 0) + share end end
      end
    end
    p = np
  end
  local liveP = 0
  for i, pr in pairs(p) do if good[i] == 1 then liveP = liveP + pr end end
  local smart = 100 * (1 - (1 - ok) ^ (1000 / T))
  -- глубина скрытой ветки у пути (как check.lua)
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
  local deepAt, maxDeep, nEntries = {}, 0, 0
  for k = 1, #path - 1 do
    local s = path[k]
    for e = G.eStart.p[s - 1], G.eStart.p[s] - 1 do
      local j = G.edges.p[e]
      if hidden[j] then nEntries = nEntries + 1; local d = depthFrom(j); if d > (deepAt[k - 1] or -1) then deepAt[k - 1] = d end; if d > maxDeep then maxDeep = d end end
    end
  end
  local dl = {}
  for k = 0, #path - 2 do if deepAt[k] then dl[#dl + 1] = k .. ":" .. deepAt[k] end end
  print(string.format("[%s] живых помечено %d | живых %d, видимых %d, скрытых %d | СКРЫТЫХ %.0f %% | ОБЕЗЬЯНА %.3f %% (жива к концу %.0f %%) | ГЛУБИНА %d у пути [%s], входов в скрытое с пути %d",
    nm, bad, live, nvis, hid, 100 * hid / math.max(1, hid + live), smart, 100 * liveP, maxDeep, table.concat(dl, " "), nEntries))
  for _, E in ipairs(ERR) do
    local n, tl, th, tv, dmin, fromPath = 0, 0, 0, 0, 1e9, 0
    for i = 1, G.n do
      if good[i] == 1 and G.flag[i] == 0 then
        for e = G.eStart.p[i - 1], G.eStart.p[i] - 1 do
          local j = G.edges.p[e]
          if G.flag[j] ~= 2 and E[2](st(i), st(j)) then
            n = n + 1
            if good[j] == 1 then tl = tl + 1 elseif lost(j) then tv = tv + 1 else
              th = th + 1; if G.depth[i] < dmin then dmin = G.depth[i] end
              if onPath[i] then fromPath = fromPath + 1 end
            end
          end
        end
      end
    end
    print(string.format("    %s: из живых %d → живые %d, скрытые %d (раньше всего с глубины %s, прямо с пути %d), видимые %d",
      E[1], n, tl, th, dmin < 1e9 and tostring(dmin) or "—", fromPath, tv))
  end
end
SV.freeGraph(G); require("ffi").C.free(good)
