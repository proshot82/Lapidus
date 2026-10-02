-- build/l8v/gen2.lua seed count [файл] — скептик кв. 8: разведка семейства «три выхода, две пробки»: выходы (В) в левой/правой
-- стене или стояком вверх; две заглушки (Н, случайная сторона); ванна с входом Н (только голова); ноги вешаются на выходы.
-- Ошибка плана по замыслу: какую течь затыкать и откуда стрелять (струя бьёт прочь от якоря, на заткнутом не повиснешь).
-- Печатаются только решаемые раскладки с обязательным брандспойтом (абляция «не бьёт» нерешаема).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local F = dofile("build/l8a/filt.lua")
local seed, count = tonumber(arg[1] or 1), tonumber(arg[2] or 200)
math.randomseed(seed)
local function rnd(a, b) return math.random(a, b) end
local function pick(t) return t[rnd(1, #t)] end
local W, H = 13, 9
local function mk()
  local rows, used = {}, {}
  for y = 1, H do rows[y] = {} for x = 1, W do rows[y][x] = (x <= 2 or x >= 12 or y == 1 or y == H) and "#" or "." end end
  local function free(x, y) return x >= 1 and x <= W and y >= 1 and y <= H and rows[y][x] == "." and not used[x .. "," .. y] end
  local objs = {}
  local function place(x, y, o) rows[y][x] = "."; used[x .. "," .. y] = true; o.at = { x, y }; objs[#objs + 1] = o end
  -- три выхода
  local nout = 3
  local tries = 0
  while nout > 0 and tries < 60 do
    tries = tries + 1
    local kind = pick({ "L", "R", "U" })
    if kind == "L" then
      local y = rnd(3, 7)
      if not used["2," .. y] and not used["2," .. (y - 1)] and not used["2," .. (y + 1)] then place(2, y, { kind = "source", ports = { right = "V" } }); nout = nout - 1 end
    elseif kind == "R" then
      local y = rnd(3, 7)
      if not used["12," .. y] and not used["12," .. (y - 1)] and not used["12," .. (y + 1)] then place(12, y, { kind = "source", ports = { left = "V" } }); nout = nout - 1 end
    else
      local x, y = rnd(4, 10), rnd(4, 8)
      if free(x, y) and free(x, y - 1) then
        place(x, y, { kind = "source", ports = { up = "V" } })
        for yy = y + 1, 8 do rows[yy][x] = "#" end
        nout = nout - 1
      end
    end
  end
  if nout > 0 then return nil end
  -- две заглушки: на полке (стена под ней) или на полу
  for i = 1, 2 do
    local ok = false
    for _ = 1, 60 do
      local x, y = rnd(3, 11), rnd(2, 8)
      if free(x, y) and (y == 8 or (free(x, y + 1) or rows[y + 1][x] == "#")) then
        local side = pick({ "left", "right", "down" })
        if y < 8 and rows[y + 1][x] == "." then rows[y + 1][x] = "#" end
        place(x, y, { kind = "fitting", what = "plug", tag = "plug" .. i, ports = { [side] = "N" } })
        ok = true; break
      end
    end
    if not ok then return nil end
  end
  -- ванна (вход Н — для головы)
  do
    local ok = false
    for _ = 1, 40 do
      local k = pick({ "floor", "L", "R", "ceil" })
      if k == "floor" then local x = rnd(3, 11); if free(x, 8) then place(x, 8, { kind = "fixture", what = "bath", ports = { up = "N" } }); ok = true end
      elseif k == "L" then local y = rnd(3, 7); if not used["2," .. y] then place(2, y, { kind = "fixture", what = "bath", ports = { right = "N" } }); ok = true end
      elseif k == "R" then local y = rnd(3, 7); if not used["12," .. y] then place(12, y, { kind = "fixture", what = "bath", ports = { left = "N" } }); ok = true end
      else local x = rnd(3, 11); if free(x, 2) then place(x, 2, { kind = "fixture", what = "bath", ports = { down = "N" } }); ok = true end end
      if ok then break end
    end
    if not ok then return nil end
  end
  for _ = 1, rnd(0, 4) do local x, y = rnd(3, 11), rnd(2, 7); if free(x, y) then rows[y][x] = "#" end end
  local lx
  for _ = 1, 30 do lx = rnd(3, 10); if free(lx, 8) and free(lx + 1, 8) then break end lx = nil end
  if not lx then return nil end
  objs[#objs + 1] = { kind = "lapidus", cells = { { lx, 8 }, { lx + 1, 8 } }, head = pick({ 1, 2 }) }
  local grid = {}
  for y = 1, H do grid[y] = table.concat(rows[y]) end
  return { id = 8, flat = 8, name = "Брандспойт", length = { 2, 5 }, pressure = pick({ 2, 2, 3 }), grid = grid, objects = objs,
    ablations = { { name = "брандспойт не бьёт", filter = F.noHose } } }
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
  local e = V.measure(G, good, VL.expert)
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
  local function objs(i) local st = R.decode(lvl, G.keys[i]); local t = {}; for q = 1, #st.pos do t[#t+1] = st.pos[q] .. (st.fixed[q] and "f" or "") end; return table.concat(t, ",") end
  local streak, maxStreak = 0, 0
  for i = 1, #path - 1 do if objs(path[i]) ~= objs(path[i+1]) then streak = 0 else streak = streak + 1; if streak > maxStreak then maxStreak = streak end end end
  local nwin = 0
  for i = 1, G.n do if G.flag[i] == 1 then nwin = nwin + 1 end end
  local n = G.n
  SV.freeGraph(G); require("ffi").C.free(good)
  if m.hiddenPct < 10 then return nil end
  local ab = SV.ablations(def, { cap = 400000 })
  if ab[1].solvable ~= false then return nil end
  return string.format("R=%d ходов %2d n=%6d win=%d скрытых %5.1f%% (знаток %5.1f%%) обез %.2f глуб %2d двери %d/%d прогулка %d",
    def.pressure, m.opt, n, nwin, m.hiddenPct, e.hiddenPct, m.smart, m.maxDeep, h1, h2, maxStreak)
end
local out = arg[3] and assert(io.open(arg[3], "a")) or io.stdout
local found = 0
for i = 1, count do
  local def = mk()
  if def then
    local r = eval(def)
    if r then
      found = found + 1
      out:write(string.format("--- seed %d #%d: %s\n", seed, i, r))
      for _, row in ipairs(def.grid) do out:write("  " .. row .. "\n") end
      for _, o in ipairs(def.objects) do
        if o.kind == "lapidus" then out:write(string.format("  lapidus %d,%d-%d,%d head=%d\n", o.cells[1][1], o.cells[1][2], o.cells[2][1], o.cells[2][2], o.head))
        else local ps = {}; for k, v in pairs(o.ports) do ps[#ps+1] = k .. "=" .. v end; table.sort(ps)
          out:write(string.format("  %s %s at %d,%d ports %s\n", o.kind, o.what or "", o.at[1], o.at[2], table.concat(ps, ","))) end
      end
      out:flush()
    end
  end
end
out:write(string.format("=== seed %d: проверено %d, найдено %d\n", seed, count, found))
out:close()
