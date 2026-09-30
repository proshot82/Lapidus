-- build/l8a/gen2.lua seed N out — генератор «от финала» для поиска ядра кв. 8 (инструмент разведки; кандидаты потом
-- доводятся руками). Строит валидную финальную сборку (выход(ы) → [переходник] → Лапидус → [переходник] → ванна,
-- лишний выход — пробка), раскладывает детали по полкам, проверяет: решаем, брандспойт обязателен, 15–40 ходов,
-- одна выигрышная. Печатает метрики и раскладку (без решений).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local F = dofile("build/l8a/filt.lua")
local seed, N, outp = tonumber(arg[1] or 1), tonumber(arg[2] or 100), arg[3] or "build/l8a/out/gen2.txt"
math.randomseed(seed)
local rnd = math.random
local function pick(t) return t[rnd(#t)] end
local W, H = 13, 9
local DIRS = { { 0, -1, "up" }, { 1, 0, "right" }, { 0, 1, "down" }, { -1, 0, "left" } }
local OPP = { up = "down", down = "up", left = "right", right = "left" }
local VEC = { up = { 0, -1 }, right = { 1, 0 }, down = { 0, 1 }, left = { -1, 0 } }
local OTH = { N = "V", V = "N" }
local cnt = { gen = 0, valid = 0, solv = 0, range = 0, ok = 0 }
local fh = assert(io.open(outp, "a"))

local function newGrid()
  local g = {}
  for y = 1, H do g[y] = {} for x = 1, W do g[y][x] = (x == 1 or x == W or y == 1 or y == H) and "#" or "." end end
  -- пол: случайные ступени
  local x = 2
  while x <= W - 1 do
    local w = rnd(2, 5)
    local hgt = pick({ 0, 0, 0, 1, 2, 3 })
    for xx = x, math.min(W - 1, x + w - 1) do for k = 1, hgt do g[H - k][xx] = "#" end end
    x = x + w
  end
  -- висячие блоки-полки
  for _ = 1, rnd(1, 3) do
    local bx, by = rnd(3, W - 2), rnd(3, 6)
    local bw = rnd(1, 2)
    for xx = bx, math.min(W - 1, bx + bw - 1) do g[by][xx] = "#" end
  end
  return g
end

local function gen()
  local g = newGrid()
  local occ = {}
  local function free(x, y) return x >= 2 and x <= W - 1 and y >= 2 and y <= H - 1 and g[y][x] == "." and not occ[x .. "," .. y] end
  -- финальный путь Лапидуса
  local L = rnd(2, 5)
  local sx, sy = rnd(2, W - 1), rnd(2, H - 1)
  if not free(sx, sy) then return nil end
  local path = { { sx, sy } }
  occ[sx .. "," .. sy] = "L"
  for i = 2, L do
    local c = path[#path]
    local opts = {}
    for _, d in ipairs(DIRS) do if free(c[1] + d[1], c[2] + d[2]) then opts[#opts + 1] = { c[1] + d[1], c[2] + d[2] } end end
    if #opts == 0 then return nil end
    local nx = pick(opts)
    path[#path + 1] = nx
    occ[nx[1] .. "," .. nx[2]] = "L"
  end
  -- path[1] — ноги (Н), path[L] — голова (В)
  local function endInfo(which)
    local e, nk
    if which == "heel" then e, nk = path[1], path[2] else e, nk = path[L], path[L - 1] end
    local dx, dy = e[1] - nk[1], e[2] - nk[2]
    local dname
    for _, d in ipairs(DIRS) do if d[1] == dx and d[2] == dy then dname = d[3] end end
    return e, dname, (which == "heel") and "N" or "V"
  end
  local objs, pieces = {}, {}
  local function put(o) local k = o.at[1] .. "," .. o.at[2]; if not free(o.at[1], o.at[2]) then return false end; occ[k] = o; objs[#objs + 1] = o; return true end
  local netEnd = pick({ "heel", "head" })
  local bathEnd = (netEnd == "heel") and "head" or "heel"
  local T = pick({ "T1", "T2", "T3", "T4", "T5" })
  -- сторона сети
  do
    local e, d, th = endInfo(netEnd)
    local c = { e[1] + VEC[d][1], e[2] + VEC[d][2] }
    if T == "T2" or T == "T5" then
      -- переходник a между выходом и Лапидусом: a в c, порт к Лапидусу OTH(th); выход за a
      local d2 = pick({ "up", "right", "down", "left" })
      if d2 == OPP[d] then return nil end
      local a = { kind = "fitting", what = "coupling", tag = "a", at = c, ports = { [OPP[d]] = OTH[th] } }
      local th2 = pick({ "N", "V" })
      a.ports[d2] = th2
      if not put(a) then return nil end
      pieces[#pieces + 1] = a
      local s = { kind = "source", at = { c[1] + VEC[d2][1], c[2] + VEC[d2][2] }, ports = { [OPP[d2]] = OTH[th2] } }
      if not put(s) then return nil end
    else
      local s = { kind = "source", at = c, ports = { [OPP[d]] = OTH[th] } }
      if not put(s) then return nil end
    end
  end
  -- сторона ванны
  do
    local e, d, th = endInfo(bathEnd)
    local c = { e[1] + VEC[d][1], e[2] + VEC[d][2] }
    if T == "T1" or T == "T4" then
      local d2 = pick({ "up", "right", "down", "left" })
      if d2 == OPP[d] then return nil end
      local a = { kind = "fitting", what = "coupling", tag = "b", at = c, ports = { [OPP[d]] = OTH[th] } }
      local th2 = pick({ "N", "V" })
      a.ports[d2] = th2
      if not put(a) then return nil end
      pieces[#pieces + 1] = a
      local k = { kind = "fixture", what = "bath", at = { c[1] + VEC[d2][1], c[2] + VEC[d2][2] }, ports = { [OPP[d2]] = OTH[th2] } }
      if not put(k) then return nil end
    else
      local k = { kind = "fixture", what = "bath", at = c, ports = { [OPP[d]] = OTH[th] } }
      if not put(k) then return nil end
    end
  end
  -- лишний выход с пробкой
  if T == "T3" or T == "T4" or T == "T5" then
    local tries = 0
    while true do
      tries = tries + 1
      if tries > 50 then return nil end
      local x, y = rnd(2, W - 1), rnd(2, H - 1)
      local d = pick({ "up", "right", "down", "left" })
      local th = pick({ "N", "V" })
      local c = { x + VEC[d][1], y + VEC[d][2] }
      if free(x, y) and free(c[1], c[2]) then
        put({ kind = "source", at = { x, y }, ports = { [d] = th } })
        local p = { kind = "fitting", what = "plug", tag = "p", at = c, ports = { [OPP[d]] = OTH[th] } }
        put(p)
        pieces[#pieces + 1] = p
        break
      end
    end
  end
  -- проверка финала
  local final = {}
  for _, o in ipairs(objs) do final[#final + 1] = o end
  final[#final + 1] = { kind = "lapidus", cells = path, head = L }
  local grid = {}
  for y = 1, H do grid[y] = table.concat(g[y]) end
  local fdef = { length = { 2, 5 }, pressure = 2, grid = grid, objects = final }
  local ok, flvl = pcall(R.compile, fdef)
  if not ok then return nil end
  local e1 = R.validate(flvl)
  if #e1 > 0 then return nil end
  local fs = R.newState(flvl)
  if not R.isWin(flvl, fs) then return nil end
  -- старт: детали — на полки (клетка пуста, под ней стена), Лапидус — на пол
  for _, o in ipairs(objs) do occ[o.at[1] .. "," .. o.at[2]] = (o.kind ~= "fitting") and o or nil end
  for _, c in ipairs(path) do occ[c[1] .. "," .. c[2]] = nil end
  for _, p in ipairs(pieces) do
    local cand = {}
    for x = 2, W - 1 do for y = 2, H - 2 do
      if free(x, y) and g[y + 1][x] == "#" then cand[#cand + 1] = { x, y } end end end
    if #cand == 0 then return nil end
    local c = pick(cand)
    p.at = c
    occ[c[1] .. "," .. c[2]] = p
  end
  local cand = {}
  for x = 2, W - 2 do for y = 2, H - 1 do
    if free(x, y) and free(x + 1, y) and g[y + 1][x] == "#" and g[y + 1][x + 1] == "#" then cand[#cand + 1] = { x, y } end end end
  if #cand == 0 then return nil end
  local c = pick(cand)
  local start = {}
  for _, o in ipairs(objs) do start[#start + 1] = o end
  start[#start + 1] = { kind = "lapidus", cells = { { c[1], c[2] }, { c[1] + 1, c[2] } }, head = pick({ 1, 2 }) }
  return { id = 8, flat = 8, name = "Брандспойт", length = { 2, 5 }, pressure = 2, grid = grid, objects = start }
end

local function ascii(def)
  local rows = {}
  for y = 1, #def.grid do rows[y] = {} for x = 1, #def.grid[y] do rows[y][x] = def.grid[y]:sub(x, x) end end
  for _, o in ipairs(def.objects) do
    if o.kind == "lapidus" then for i, c in ipairs(o.cells) do rows[c[2]][c[1]] = (i == o.head) and "H" or "f" end
    else rows[o.at[2]][o.at[1]] = ({ source = "S", fixture = "K", fitting = o.tag })[o.kind] end
  end
  local t = {} for y = 1, #rows do t[y] = table.concat(rows[y]) end
  return table.concat(t, "/")
end
local function ser(def)
  local t = {}
  for _, o in ipairs(def.objects) do
    if o.kind ~= "lapidus" then
      local ps = {}
      for k, v in pairs(o.ports) do ps[#ps + 1] = k .. "=" .. v end
      table.sort(ps)
      t[#t + 1] = string.format("%s%s@%d,%d[%s]", o.kind:sub(1, 3), o.tag or "", o.at[1], o.at[2], table.concat(ps, ","))
    else t[#t + 1] = string.format("L%d,%d-%d,%d h%d", o.cells[1][1], o.cells[1][2], o.cells[2][1], o.cells[2][2], o.head) end
  end
  return table.concat(t, " ")
end

for it = 1, N do
  local def = gen()
  if def then
    cnt.gen = cnt.gen + 1
    local ok, lvl = pcall(R.compile, def)
    if ok then
      local errs, warns = R.validate(lvl)
      if #errs == 0 and #warns == 0 then
        cnt.valid = cnt.valid + 1
        local G = SV.explore(lvl, 300000)
        if G and G.firstWin then
          cnt.solv = cnt.solv + 1
          local opt = G.depth[G.firstWin]
          local nwin = 0
          for i = 1, G.n do if G.flag[i] == 1 then nwin = nwin + 1 end end
          if opt >= 15 and opt <= 40 and nwin == 1 then
            cnt.range = cnt.range + 1
            local G2 = SV.explore(lvl, 300000, F.noHose)
            local need = G2 and not G2.firstWin
            SV.freeGraph(G2)
            if need then
              local good = SV.goodSet(G)
              local VL = V.compute(lvl, G, def, good)
              local m = V.measure(G, good, VL.newbie)
              cnt.ok = cnt.ok + 1
              fh:write(string.format("s%d i%d | ход %d n %d жив %d СКР %.1f%% обез %.3f глуб %d [%s] | %s | %s\n",
                seed, it, opt, G.n, m.live, m.hiddenPct, m.smart, m.maxDeep, m.deepList, ser(def), ascii(def)))
              fh:flush()
              require("ffi").C.free(good)
            end
          end
        end
        SV.freeGraph(G)
      end
    end
  end
end
fh:close()
print(string.format("seed %d: построено %d, валидных %d, решаемых %d, в коридоре %d, годных %d", seed, cnt.gen, cnt.valid, cnt.solv, cnt.range, cnt.ok))
