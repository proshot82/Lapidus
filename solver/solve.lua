-- solver/solve.lua — полный анализ уровня по §7: BFS по всему пространству состояний
-- на том же ядре правил. Модуль + CLI: luajit solver/solve.lua levels/01.lua [cap]
-- CLI печатает только метрики; решения пишутся лишь в puzzles/solutions.json.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local ffi = require("ffi")
pcall(ffi.cdef, [[
void *malloc(size_t size);
void *realloc(void *ptr, size_t size);
void free(void *ptr);
]])

-- растущий вектор int32 вне кучи Lua (десятки миллионов рёбер)
local Vec = {}
Vec.__index = Vec
local function newVec(cap)
  cap = cap or 4096
  local p = ffi.C.malloc(cap * 4)
  assert(p ~= nil, "malloc failed")
  return setmetatable({ n = 0, cap = cap, p = ffi.cast("int32_t*", p) }, Vec)
end
function Vec:push(x)
  if self.n >= self.cap then
    local nc = self.cap * 2
    local p = ffi.C.realloc(self.p, nc * 4)
    assert(p ~= nil, "realloc failed")
    self.p = ffi.cast("int32_t*", p)
    self.cap = nc
  end
  self.p[self.n] = x
  self.n = self.n + 1
end
function Vec:free()
  if self.p ~= nil then ffi.C.free(self.p); self.p = nil end
end
local function calloc32(n)
  local p = ffi.C.malloc((n + 2) * 4)
  assert(p ~= nil, "malloc failed")
  ffi.fill(p, (n + 2) * 4, 0)
  return ffi.cast("int32_t*", p)
end

local M = {}

function M.loadDef(path)
  local chunk = assert(loadfile(path))
  return chunk()
end

function M.deepcopy(t, seen)
  if type(t) ~= "table" then return t end
  seen = seen or {}
  if seen[t] then return seen[t] end
  local c = {}
  seen[t] = c
  for k, v in pairs(t) do c[M.deepcopy(k, seen)] = M.deepcopy(v, seen) end
  return c
end

-- Полный BFS. Состояния победы и «смыло» терминальны.
function M.explore(lvl, cap, filter)
  cap = cap or 5000000
  local start = R.newState(lvl)
  local k0 = R.key(start)
  local index = { [k0] = 1 }
  local keys = { k0 }
  local depth = { 0 }
  local parent = { 0 }
  local pmove = { 0 }
  local flag = { 0 } -- 0 обычное, 1 победа, 2 «смыло»
  if R.isWin(lvl, start) then flag[1] = 1 end
  local eStart = newVec(65536)
  local edges = newVec(262144)
  local unstable = 0
  local firstWin = (flag[1] == 1) and 1 or nil
  local qi = 1
  while qi <= #keys do
    local id = qi
    qi = qi + 1
    eStart:push(edges.n)
    if flag[id] == 0 then
      local st = R.decode(lvl, keys[id])
      for m = 1, 8 do
        local mm = R.MOVES[m]
        local ns, _, stable = R.move(lvl, st, mm.which, mm.dir)
        if ns and filter and not filter(lvl, st, ns) then ns = nil end
        if ns then
          if stable == false then unstable = unstable + 1 end
          local k = R.key(ns)
          local nid = index[k]
          if not nid then
            nid = #keys + 1
            if nid > cap then
              eStart:free(); edges:free()
              return nil, "cap"
            end
            keys[nid] = k
            index[k] = nid
            depth[nid] = depth[id] + 1
            parent[nid] = id
            pmove[nid] = m
            if ns.dead then
              flag[nid] = 2
            elseif R.isWin(lvl, ns) then
              flag[nid] = 1
              if not firstWin then firstWin = nid end
            else
              flag[nid] = 0
            end
          end
          edges:push(nid)
        end
      end
    end
  end
  eStart:push(edges.n)
  return {
    keys = keys, index = index, depth = depth, parent = parent, pmove = pmove, flag = flag,
    eStart = eStart, edges = edges, unstable = unstable, firstWin = firstWin, n = #keys,
  }
end

function M.freeGraph(G)
  if G then G.eStart:free(); G.edges:free() end
end

-- Состояния, из которых победа достижима (обратный BFS от побед).
function M.goodSet(G)
  local n = G.n
  local E, ES = G.edges.p, G.eStart.p
  local indeg = calloc32(n)
  for i = 1, n do
    for e = ES[i - 1], ES[i] - 1 do indeg[E[e]] = indeg[E[e]] + 1 end
  end
  local off = calloc32(n + 1)
  local acc = 0
  for i = 1, n do off[i] = acc; acc = acc + indeg[i] end
  off[n + 1] = acc
  local rev = calloc32(acc)
  local fill = indeg -- переиспользуем как счётчик заполнения
  ffi.fill(fill, (n + 2) * 4, 0)
  for i = 1, n do
    for e = ES[i - 1], ES[i] - 1 do
      local j = E[e]
      rev[off[j] + fill[j]] = i
      fill[j] = fill[j] + 1
    end
  end
  local good = ffi.cast("uint8_t*", ffi.C.malloc(n + 2))
  ffi.fill(good, n + 2, 0)
  local queue = calloc32(n)
  local qh, qt = 0, 0
  for i = 1, n do
    if G.flag[i] == 1 then good[i] = 1; queue[qt] = i; qt = qt + 1 end
  end
  while qh < qt do
    local j = queue[qh]
    qh = qh + 1
    for e = off[j], off[j + 1] - 1 do
      local i = rev[e]
      if good[i] == 0 then good[i] = 1; queue[qt] = i; qt = qt + 1 end
    end
  end
  ffi.C.free(indeg); ffi.C.free(off); ffi.C.free(rev); ffi.C.free(queue)
  return good
end

function M.regionAtLeast(G, t, limit)
  local seen = { [t] = true }
  local q = { t }
  local h, count = 1, 1
  local E, ES = G.edges.p, G.eStart.p
  while h <= #q do
    local s = q[h]
    h = h + 1
    for e = ES[s - 1], ES[s] - 1 do
      local u = E[e]
      if not seen[u] then
        seen[u] = true
        q[#q + 1] = u
        count = count + 1
        if count >= limit then return true end
      end
    end
  end
  return count >= limit
end

-- Метрики §7. Возвращает таблицу результата (решение — в res.solution, наружу не печатать).
function M.analyze(def, opts)
  opts = opts or {}
  local lvl = R.compile(def)
  local errs, warns = R.validate(lvl)
  local res = { id = def.id, name = def.name, errors = errs, warnings = warns }
  if #errs > 0 then return res end
  local t0 = os.clock()
  local G = M.explore(lvl, opts.cap)
  if not G then res.capped = true; res.time = os.clock() - t0; return res end
  res.states = G.n
  res.unstable = G.unstable
  local good = M.goodSet(G)
  local ngood, nwin, ndead = 0, 0, 0
  for i = 1, G.n do
    if good[i] == 1 then ngood = ngood + 1 end
    if G.flag[i] == 1 then nwin = nwin + 1 end
    if G.flag[i] == 2 then ndead = ndead + 1 end
  end
  res.winStates = nwin
  res.washStates = ndead
  res.deadPct = (G.n > 0) and (100 * (G.n - ngood) / G.n) or 0
  res.solvable = G.firstWin ~= nil
  if G.firstWin then
    res.minMoves = G.depth[G.firstWin]
    local path, onPath = {}, {}
    local x = G.firstWin
    while x ~= 1 do
      table.insert(path, 1, G.pmove[x])
      x = G.parent[x]
      onPath[#onPath + 1] = x
    end
    res.solution = path
    local fb, sizes = 0, {}
    local seenEntry = {}
    for _, s in ipairs(onPath) do
      if G.flag[s] == 0 then
        for e = G.eStart.p[s - 1], G.eStart.p[s] - 1 do
          local t = G.edges.p[e]
          if good[t] == 0 and not seenEntry[t] then
            seenEntry[t] = true
            if M.regionAtLeast(G, t, 50) then fb = fb + 1 end
          end
        end
      end
    end
    res.falseBranches = fb
  end
  ffi.C.free(good)
  if opts.keepGraph then res.graph = G else M.freeGraph(G) end
  res.time = os.clock() - t0
  return res
end

-- Абляции: каждая мутация уровня обязана сделать его нерешаемым.
function M.ablations(def, opts)
  local out = {}
  for _, ab in ipairs(def.ablations or {}) do
    local d2 = M.deepcopy(def)
    d2.ablations = nil
    ab.mutate(d2)
    local lvl2 = R.compile(d2)
    local G2 = M.explore(lvl2, opts and opts.cap)
    local solvable
    if not G2 then solvable = "unknown" else solvable = (G2.firstWin ~= nil) end
    M.freeGraph(G2)
    out[#out + 1] = { name = ab.name, solvable = solvable }
  end
  return out
end

function M.summary(res)
  if #(res.errors or {}) > 0 then return "INVALID: " .. table.concat(res.errors, "; ") end
  if res.capped then return "CAPPED (state space above cap)" end
  return string.format("states=%d solvable=%s minMoves=%s deadPct=%.1f falseBranches=%s winStates=%d unstable=%d time=%.1fs",
    res.states, tostring(res.solvable), tostring(res.minMoves), res.deadPct, tostring(res.falseBranches),
    res.winStates, res.unstable, res.time)
end

-- Мутация абляции: декларативно (flip/remove по тегу, pressure) или функцией mutate.
function M.applyAblation(d, ab)
  if ab.flip then
    for _, o in ipairs(d.objects) do
      if o.tag == ab.flip and o.ports then
        for k, v in pairs(o.ports) do o.ports[k] = (v == "N") and "V" or "N" end
      end
    end
  end
  if ab.remove then
    local keep = {}
    for _, o in ipairs(d.objects) do if o.tag ~= ab.remove then keep[#keep + 1] = o end end
    d.objects = keep
  end
  if ab.pressure then d.pressure = ab.pressure end
  if ab.mutate then ab.mutate(d) end
  return d
end

function M.ablations(def, opts)
  local out = {}
  for _, ab in ipairs(def.ablations or {}) do
    local d2 = M.deepcopy(def)
    d2.ablations = nil
    M.applyAblation(d2, ab)
    local solvable
    local ok, lvl2 = pcall(R.compile, d2)
    if not ok or #R.validate(lvl2) > 0 then
      solvable = false
    else
      local G2 = M.explore(lvl2, opts and opts.cap, ab.filter)
      if not G2 then solvable = "unknown" else solvable = (G2.firstWin ~= nil) end
      M.freeGraph(G2)
    end
    out[#out + 1] = { name = ab.name, solvable = solvable }
  end
  return out
end

if arg and arg[0] and arg[0]:match("solve%.lua$") and arg[1] then
  local def = M.loadDef(arg[1])
  local res = M.analyze(def, { cap = tonumber(arg[2]) })
  print((def.name or arg[1]) .. ": " .. M.summary(res))
  for _, w in ipairs(res.warnings or {}) do print("  warning: " .. w) end
end

return M
