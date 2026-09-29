-- build/l4v3/lib.lua — общий загрузчик слепой проверки кв. 4 (t16, t6w): граф, разметки, кратчайшие пути, классы.
-- Только метрики; ходы не печатаются.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local L = {}

function L.load(file, opts)
  opts = opts or {}
  if opts.pocket then V.POCKET = opts.pocket end
  local def = type(file) == "table" and file or dofile(file)
  local lvl = R.compile(def)
  local G = SV.explore(lvl, 3000000, opts.filter)
  if not G or not G.firstWin then return { unsolvable = true, n = G and G.n } end
  local good = SV.goodSet(G)
  local VL = V.compute(lvl, G, def, good)
  local def0 = {}
  for k, v in pairs(def) do def0[k] = v end
  def0.visibleLoss = nil
  local VL0 = V.compute(lvl, G, def0, good)
  local A = { def = def, lvl = lvl, G = G, good = good, VL = VL, VL0 = VL0, sts = VL.states, V = V, R = R, SV = SV }
  local Q = {}
  for q, p in ipairs(lvl.pieces) do
    if p.tag then Q[p.tag] = q end
    if p.source then A.S = p.start end
    if p.fixture then A.wash = p.start end
    if p.kind == "pipe" then A.pipe = p.start end
  end
  A.Q = Q
  A.B = lvl.nb[A.S][1]; A.T = lvl.nb[A.B][1]
  A.washIn = lvl.nb[A.wash][1]
  A.pipeOut = lvl.nb[A.pipe][2]
  -- клетки, где деталь бывает свободной и живой
  A.liveFree = {}
  for tag, q in pairs(Q) do A.liveFree[tag] = {} end
  for i = 1, G.n do
    if G.flag[i] ~= 2 and good[i] == 1 then
      local st = A.sts[i]
      for tag, q in pairs(Q) do if st.pos[q] ~= 0 and not st.fixed[q] then A.liveFree[tag][st.pos[q]] = true end end
    end
  end
  -- кратчайшие пути: расстояние до выигрыша
  local ES, E, flag = G.eStart.p, G.edges.p, G.flag
  local cnt = {}
  for i = 1, G.n + 1 do cnt[i] = 0 end
  for i = 1, G.n do for e = ES[i - 1], ES[i] - 1 do local j = E[e]; cnt[j] = cnt[j] + 1 end end
  local st0, s = {}, 1
  for i = 1, G.n do st0[i] = s; s = s + cnt[i] end; st0[G.n + 1] = s
  local fill, rv = {}, {}
  for i = 1, G.n do fill[i] = st0[i] end
  for i = 1, G.n do for e = ES[i - 1], ES[i] - 1 do local j = E[e]; rv[fill[j]] = i; fill[j] = fill[j] + 1 end end
  A.rstart, A.rev = st0, rv
  local toWin, q, h = {}, {}, 1
  for i = 1, G.n do if flag[i] == 1 then toWin[i] = 0; q[#q + 1] = i end end
  while h <= #q do local j = q[h]; h = h + 1
    for k = st0[j], st0[j + 1] - 1 do local i = rv[k]; if toWin[i] == nil and flag[i] ~= 2 then toWin[i] = toWin[j] + 1; q[#q + 1] = i end end end
  A.toWin = toWin
  A.opt = G.depth[G.firstWin]
  local onSP = {}
  for i = 1, G.n do if toWin[i] and G.depth[i] + toWin[i] == A.opt then onSP[i] = true end end
  A.onSP = onSP
  -- путь check.lua (первый найденный)
  local path, x = {}, G.firstWin
  while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
  table.insert(path, 1, 1)
  A.path = path
  return A
end

local function xy(A, c) return A.R.xy(A.lvl, c) end
L.xy = xy

-- свободна ли деталь q «внизу» (ниже антресоли: y >= 5)
function L.lowFree(A, st, q)
  local c = st.pos[q]
  if c == 0 or st.fixed[q] then return false end
  local _, y = xy(A, c)
  return y >= 5
end

-- классы скрытых (порядок = приоритет)
function L.classes(A)
  local Q = A.Q
  local e, n, c = Q.elb, Q.nip, Q.cpl
  local function pair(st)
    local m = {}
    for _, q in ipairs({ e, n, c }) do
      if st.pos[q] ~= 0 and not st.fixed[q] then
        if m[st.asm[q]] then return true end
        m[st.asm[q]] = true
      end
    end
    return false
  end
  return {
    { "EP", "угольник прикручен к выходу трубы шахты (порт занят)", function(st) return st.fixed[e] and st.pos[e] == A.pipeOut end },
    { "EX", "угольник прикручен в другом не своём месте", function(st) return st.fixed[e] and st.pos[e] ~= A.washIn and st.pos[e] ~= A.pipeOut end },
    { "NW", "ниппель пойман машинкой (сито)", function(st) return st.fixed[n] and st.pos[n] == A.washIn end },
    { "NX", "ниппель прикручен в другом не своём месте", function(st) return st.fixed[n] and st.pos[n] ~= A.T and st.pos[n] ~= A.washIn end },
    { "CX", "муфта прикручена не на стояке", function(st) return st.fixed[c] and st.pos[c] ~= A.B end },
    { "PR", "две детали свинчены в свободную пару", pair },
    { "EF", "угольник свободен внизу (упал мимо спуска)", function(st) return L.lowFree(A, st, e) end },
    { "CD", "муфта свободна в клетке, где она никогда не жива", function(st) return st.pos[c] ~= 0 and not st.fixed[c] and not A.liveFree.cpl[st.pos[c]] end },
    { "ND", "ниппель свободен в клетке, где он никогда не жив", function(st) return st.pos[n] ~= 0 and not st.fixed[n] and not A.liveFree.nip[st.pos[n]] end },
    { "ED", "угольник свободен наверху в клетке, где он никогда не жив", function(st) return st.pos[e] ~= 0 and not st.fixed[e] and not A.liveFree.elb[st.pos[e]] end },
    { "OR", "все детали в «живых» клетках — неверное сочетание/порядок", function() return true end },
  }
end

function L.classOf(A, cls, st)
  for k, c in ipairs(cls) do if c[3](st) then return k end end
end

-- разметка: newbie + добавочные классы (по кодам)
function L.mark(A, cls, extra)
  local set = {}
  for _, code in ipairs(extra or {}) do set[code] = true end
  local M = {}
  for i = 1, A.G.n do
    if A.G.flag[i] ~= 2 then
      local v = A.VL.newbie[i]
      if not v and A.good[i] ~= 1 and next(set) then
        local k = L.classOf(A, cls, A.sts[i])
        if set[cls[k][1]] then v = true end
      end
      M[i] = v
    end
  end
  return M
end

-- двери с пути path (или со всех кратчайших): шаг -> {класс -> число}; hidden — таблица скрытых
function L.doors(A, hidden, onlyPath)
  local G = A.G
  local ES, E = G.eStart.p, G.edges.p
  local res = {}
  local src = {}
  if onlyPath then for k = 1, #A.path - 1 do src[A.path[k]] = k - 1 end
  else for i in pairs(A.onSP) do src[i] = G.depth[i] end end
  for i, step in pairs(src) do
    for e = ES[i - 1], ES[i] - 1 do local j = E[e]
      if hidden[j] then res[#res + 1] = { from = i, to = j, step = step } end
    end
  end
  table.sort(res, function(a, b) return a.step < b.step end)
  return res
end

-- глубина скрытой области от j (как в vislib) и размер
function L.depthFrom(A, hidden, j)
  local G = A.G
  local ES, E = G.eStart.p, G.edges.p
  local d, q, h, maxd = { [j] = 0 }, { j }, 1, 0
  while h <= #q do local u = q[h]; h = h + 1
    for e = ES[u - 1], ES[u] - 1 do local v = E[e]
      if hidden[v] and d[v] == nil then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; q[#q + 1] = v end end end
  return maxd, #q
end

-- кратчайшее число ходов из j до видимого проигрыша (по разметке lost)
function L.toVisible(A, lost, j)
  local G = A.G
  local ES, E = G.eStart.p, G.edges.p
  local d, q, h = { [j] = 0 }, { j }, 1
  while h <= #q do local u = q[h]; h = h + 1
    if lost[u] or G.flag[u] == 2 then return d[u] end
    for e = ES[u - 1], ES[u] - 1 do local v = E[e]; if d[v] == nil then d[v] = d[u] + 1; q[#q + 1] = v end end end
  return nil
end

function L.hiddenOf(A, lost)
  local H, nh, nl = {}, 0, 0
  for i = 1, A.G.n do if A.G.flag[i] ~= 2 then
    if A.good[i] == 1 then nl = nl + 1 elseif not lost[i] then H[i] = true; nh = nh + 1 end end end
  return H, nh, nl
end

function L.cfg(A, st)
  local t = {}
  for _, tag in ipairs({ "cpl", "nip", "elb" }) do
    local q = A.Q[tag]
    if st.pos[q] == 0 then t[#t + 1] = tag .. "=смыт" else
      local x, y = xy(A, st.pos[q]); t[#t + 1] = string.format("%s(%d,%d)%s", tag, x, y, st.fixed[q] and "F" or "") end
  end
  return table.concat(t, " ")
end

function L.free(A) A.SV.freeGraph(A.G); require("ffi").C.free(A.good) end
return L
