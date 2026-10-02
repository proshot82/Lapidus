-- build/l8v/mut.lua база.lua итераций семя [файл] — скептик кв. 8: мутатор-восхождение от решаемой базы.
-- Мутации: стена↔пусто (внутри рамки), сдвиг детали/стояка/ванны/старта на клетку, напор 2↔3. Принимается раскладка,
-- если решаема, брандспойт обязателен (абляция «не бьёт» нерешаема) и оценка не хуже: оценка = скрытых % (новичок)
-- + 10·(есть дверь в первой половине) + 10·(есть дверь во второй). Печатает каждое улучшение (сетка и объекты).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local F = dofile("build/l8a/filt.lua")
local base = dofile(arg[1])
local iters, seed = tonumber(arg[2] or 300), tonumber(arg[3] or 1)
local out = arg[4] and assert(io.open(arg[4], "a")) or io.stdout
math.randomseed(seed)
local function rnd(a, b) return math.random(a, b) end
local function copy(def)
  local d = SV.deepcopy(def)
  d.ablations = { { name = "брандспойт не бьёт", filter = F.noHose } }
  d.controls = nil
  return d
end
local function cellAt(d, x, y) return d.grid[y]:sub(x, x) end
local function setCell(d, x, y, ch) d.grid[y] = d.grid[y]:sub(1, x - 1) .. ch .. d.grid[y]:sub(x + 1) end
local function occupied(d, x, y)
  for _, o in ipairs(d.objects) do
    if o.at and o.at[1] == x and o.at[2] == y then return true end
    if o.cells then for _, c in ipairs(o.cells) do if c[1] == x and c[2] == y then return true end end end
  end
  return false
end
local function mutate(d)
  local W, H = #d.grid[1], #d.grid
  local k = rnd(1, 10)
  if k <= 5 then
    local x, y = rnd(2, W - 1), rnd(2, H - 1)
    if occupied(d, x, y) then return false end
    setCell(d, x, y, cellAt(d, x, y) == "#" and "." or "#")
    return true
  elseif k <= 9 then
    local o = d.objects[rnd(1, #d.objects)]
    local dx, dy = ({ 1, -1, 0, 0 })[rnd(1, 4)], ({ 0, 0, 1, -1 })[rnd(1, 4)]
    if o.cells then
      for _, c in ipairs(o.cells) do
        local nx, ny = c[1] + dx, c[2] + dy
        if nx < 2 or nx > W - 1 or ny < 2 or ny > H - 1 or cellAt(d, nx, ny) ~= "." then return false end
      end
      for _, c in ipairs(o.cells) do c[1], c[2] = c[1] + dx, c[2] + dy end
      for _, c in ipairs(o.cells) do if occupied(d, c[1], c[2]) then return false end end
      return true
    else
      local nx, ny = o.at[1] + dx, o.at[2] + dy
      if nx < 2 or nx > W - 1 or ny < 2 or ny > H - 1 then return false end
      if occupied(d, nx, ny) then return false end
      if cellAt(d, nx, ny) == "#" then setCell(d, nx, ny, ".") end
      o.at = { nx, ny }
      return true
    end
  else
    d.pressure = (d.pressure == 2) and 3 or 2
    return true
  end
end
local function eval(def)
  local ok, lvl = pcall(R.compile, def)
  if not ok then return nil end
  if #R.validate(lvl) > 0 then return nil end
  local G = SV.explore(lvl, 400000)
  if not G or not G.firstWin then if G then SV.freeGraph(G) end return nil end
  local good = SV.goodSet(G)
  local VL = V.compute(lvl, G, def, good)
  local m = V.measure(G, good, VL.newbie)
  local path, x = {}, G.firstWin
  while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
  table.insert(path, 1, 1)
  local ES, E = G.eStart.p, G.edges.p
  local h1, h2 = 0, 0
  for k = 1, #path - 1 do
    local s, c = path[k], 0
    for e = ES[s - 1], ES[s] - 1 do if m.hidden[E[e]] then c = c + 1 end end
    if c > 0 then if (k - 1) < (#path - 1) / 2 then h1 = h1 + 1 else h2 = h2 + 1 end end
  end
  local nwin = 0
  for i = 1, G.n do if G.flag[i] == 1 then nwin = nwin + 1 end end
  local n = G.n
  SV.freeGraph(G); require("ffi").C.free(good)
  local ab = SV.ablations(def, { cap = 400000 })
  if ab[1].solvable ~= false then return nil end
  local score = m.hiddenPct + (h1 > 0 and 10 or 0) + (h2 > 0 and 10 or 0) - (nwin > 1 and 5 or 0)
  return score, string.format("R=%d ходов %2d n=%6d win=%d скрытых %5.1f%% обез %.2f глуб %2d двери %d/%d", def.pressure, m.opt, n, nwin, m.hiddenPct, m.smart, m.maxDeep, h1, h2)
end
local function dump(d, label)
  out:write(label .. "\n")
  for _, row in ipairs(d.grid) do out:write("  " .. row .. "\n") end
  for _, o in ipairs(d.objects) do
    if o.kind == "lapidus" then out:write(string.format("  lapidus %d,%d-%d,%d head=%d\n", o.cells[1][1], o.cells[1][2], o.cells[2][1], o.cells[2][2], o.head))
    else local ps = {}; for k, v in pairs(o.ports) do ps[#ps+1] = k .. "=" .. v end; table.sort(ps)
      out:write(string.format("  %s %s %s at %d,%d ports %s\n", o.kind, o.what or "", o.tag or "", o.at[1], o.at[2], table.concat(ps, ","))) end
  end
  out:flush()
end
local cur = copy(base)
local curScore, curTxt = eval(cur)
if not curScore then out:write("база не проходит фильтр (нерешаема или брандспойт не обязателен)\n"); out:close(); return end
out:write(string.format("база: %s (оценка %.1f)\n", curTxt, curScore)); out:flush()
local best = curScore
for i = 1, iters do
  local d = copy(cur)
  local nm = rnd(1, 2)
  local ok = true
  for _ = 1, nm do if not mutate(d) then ok = false end end
  if ok then
    local s, txt = eval(d)
    if s and s >= curScore then
      cur, curScore = d, s
      if s > best then best = s; dump(d, string.format("--- улучшение на шаге %d: %s (оценка %.1f)", i, txt, s)) end
    end
  end
  if i % 50 == 0 then out:write(string.format("... шаг %d, текущая оценка %.1f, лучшая %.1f\n", i, curScore, best)); out:flush() end
end
out:write(string.format("=== готово: лучшая оценка %.1f\n", best))
out:close()
