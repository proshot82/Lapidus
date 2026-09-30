-- build/l8a/hill.lua база.lua итераций seed out.lua — локальный поиск (мутатор авторского скелета): переключает клетки
-- стен и сдвигает незакреплённые объекты на ±1, сохраняя состав элементов. Цель: решаем, брандспойт обязателен,
-- 15–40 ходов, одна выигрышная; максимизирует двери с пути (в обеих половинах, хвост ≥ 8) и долю скрытых.
-- Печатает только метрики; лучшую раскладку пишет в out.lua (без решения).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local F = dofile("build/l8a/filt.lua")
local base = dofile(arg[1])
local ITER, seed, outp = tonumber(arg[2] or 200), tonumber(arg[3] or 1), arg[4] or "build/l8a/out/hill.lua"
math.randomseed(seed)
local function copy(t) if type(t) ~= "table" then return t end local c = {} for k, v in pairs(t) do c[k] = copy(v) end return c end
local function strip(d) local c = { id = 8, flat = 8, name = d.name, length = copy(d.length), pressure = d.pressure, grid = copy(d.grid), objects = copy(d.objects) } return c end
local function eval(d)
  local ok, lvl = pcall(R.compile, d)
  if not ok then return -1e9 end
  local errs, warns = R.validate(lvl)
  if #errs > 0 or #warns > 0 then return -1e9 end
  local G = SV.explore(lvl, 400000)
  if not G then return -1e9 end
  if not G.firstWin then local s = -1000 + 0; SV.freeGraph(G); return s end
  local opt = G.depth[G.firstWin]
  local nwin = 0
  for i = 1, G.n do if G.flag[i] == 1 then nwin = nwin + 1 end end
  local score = 0
  if opt < 15 then score = score - 30 * (15 - opt) elseif opt > 40 then score = score - 30 * (opt - 40) end
  if nwin > 1 then score = score - 200 end
  local good = SV.goodSet(G)
  local VL = V.compute(lvl, G, d, good)
  local m = V.measure(G, good, VL.newbie)
  -- двери с пути по половинам с хвостом ≥ 8
  local ES, E = G.eStart.p, G.edges.p
  local path = m.path
  local half = { 0, 0 }
  for k = 1, #path - 1 do
    local s = path[k]
    local best = 0
    for e = ES[s - 1], ES[s] - 1 do
      local j = E[e]
      if m.hidden[j] then
        local dd, q, h, maxd = { [j] = 0 }, { j }, 1, 0
        while h <= #q and maxd < 8 do local u = q[h]; h = h + 1
          for e2 = ES[u - 1], ES[u] - 1 do local v = E[e2]; if m.hidden[v] and dd[v] == nil then dd[v] = dd[u] + 1; if dd[v] > maxd then maxd = dd[v] end; q[#q + 1] = v end end end
        if maxd > best then best = maxd end
      end
    end
    if best >= 8 then local hh = ((k - 1) < (#path - 1) / 2) and 1 or 2; half[hh] = half[hh] + 1 end
  end
  score = score + math.min(m.hiddenPct, 60) + 25 * math.min(half[1], 2) + 40 * math.min(half[2], 2)
  if m.smart > 0.2 then score = score - 20 * math.min(5, m.smart) end
  require("ffi").C.free(good)
  SV.freeGraph(G)
  -- брандспойт обязателен (дорого — только для перспективных)
  local G2 = SV.explore(lvl, 400000, F.noHose)
  local need = G2 and not G2.firstWin
  SV.freeGraph(G2)
  if not need then score = score - 150 end
  return score, string.format("ход %d n %d вывигр %d СКР %.1f%% обез %.2f двери(≥8) %d/%d брандспойт %s", opt, G.n, nwin, m.hiddenPct, m.smart, half[1], half[2], need and "нужен" or "НЕ нужен")
end
local function mutate(d)
  local c = strip(d)
  local r = math.random()
  if r < 0.6 then
    for _ = 1, 20 do
      local x, y = math.random(2, #c.grid[1] - 1), math.random(2, #c.grid - 1)
      local occ = false
      for _, o in ipairs(c.objects) do
        if o.at and o.at[1] == x and o.at[2] == y then occ = true end
        if o.cells then for _, cc in ipairs(o.cells) do if cc[1] == x and cc[2] == y then occ = true end end end
      end
      if not occ then
        local row = c.grid[y]
        local ch = row:sub(x, x) == "#" and "." or "#"
        c.grid[y] = row:sub(1, x - 1) .. ch .. row:sub(x + 1)
        return c
      end
    end
  else
    local movables = {}
    for i, o in ipairs(c.objects) do movables[#movables + 1] = i end
    local o = c.objects[movables[math.random(#movables)]]
    local dx, dy = ({ -1, 1, 0, 0 })[math.random(4)], 0
    if dx == 0 then dy = ({ -1, 1 })[math.random(2)] end
    if o.at then o.at = { o.at[1] + dx, o.at[2] + dy }
    else for _, cc in ipairs(o.cells) do cc[1] = cc[1] + dx; cc[2] = cc[2] + dy end end
    return c
  end
  return c
end
local function ser(d)
  local t = { "-- найдено hill.lua (мутатор скелета); решение не приводится", "return {", "  id = 8, flat = 8, name = \"Брандспойт\",", string.format("  length = { %d, %d }, pressure = %d,", d.length[1], d.length[2], d.pressure), "  grid = {" }
  for _, r in ipairs(d.grid) do t[#t + 1] = string.format("    %q,", r) end
  t[#t + 1] = "  },"
  t[#t + 1] = "  objects = {"
  for _, o in ipairs(d.objects) do
    if o.kind == "lapidus" then
      local cs = {}
      for _, cc in ipairs(o.cells) do cs[#cs + 1] = string.format("{ %d, %d }", cc[1], cc[2]) end
      t[#t + 1] = string.format("    { kind = \"lapidus\", cells = { %s }, head = %d },", table.concat(cs, ", "), o.head)
    else
      local ps = {}
      for k, v in pairs(o.ports) do ps[#ps + 1] = string.format("%s = %q", k, v) end
      table.sort(ps)
      t[#t + 1] = string.format("    { kind = %q, what = %q, tag = %s, at = { %d, %d }, ports = { %s } },", o.kind, o.what or o.kind, o.tag and string.format("%q", o.tag) or "nil", o.at[1], o.at[2], table.concat(ps, ", "))
    end
  end
  t[#t + 1] = "  },"
  t[#t + 1] = "}"
  return table.concat(t, "\n") .. "\n"
end
local cur = strip(base)
local curS, curI = eval(cur)
print("старт: " .. tostring(curS) .. " " .. tostring(curI))
local best, bestS = cur, curS
for it = 1, ITER do
  local c = mutate(cur)
  local s, info = eval(c)
  if os.getenv("HV") then print(it, s, info) end
  if s >= curS or math.random() < 0.05 then
    cur, curS = c, s
    if s > bestS then
      best, bestS = c, s
      print(string.format("it %d: %.1f %s", it, s, info)); io.stdout:flush()
      local fh = io.open(outp, "w"); fh:write(ser(best)); fh:close()
    end
  end
end
print("лучший: " .. bestS)
