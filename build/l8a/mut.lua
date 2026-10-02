-- build/l8a/mut.lua seed N out — мутатор авторского скелета кв. 8 (уступ со стояком слева, полка с деталью, второй выход Н,
-- ванна, пробка): случайные вариации позиций; отбор: решаем, брандспойт обязателен, 15–40 ходов, одна выигрышная.
-- Печатает только метрики и раскладку (без решений).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local F = dofile("build/l8a/filt.lua")
local seed, N, out = tonumber(arg[1] or 1), tonumber(arg[2] or 100), arg[3] or "build/l8a/out/mut.txt"
math.randomseed(seed)
local rnd = math.random
local function pick(t) return t[rnd(#t)] end
local fh = assert(io.open(out, "a"))
local PIECES = {
  { what = "elbow", tag = "elb", ports = { down = "N", left = "V" } },
  { what = "elbow", tag = "elb", ports = { down = "N", right = "V" } },
  { what = "elbow", tag = "elb", ports = { down = "N", left = "N" } },
  { what = "elbow", tag = "elb", ports = { down = "N", right = "N" } },
  { what = "nipple", tag = "nip", ports = { down = "N", up = "V" } },
  { what = "nipple", tag = "nip", ports = { down = "N", up = "N" } },
  { what = "nipple", tag = "nip", ports = { left = "N", right = "N" } },
  { what = "coupling", tag = "cpl", ports = { left = "N", right = "V" } },
  { what = "coupling", tag = "cpl", ports = { left = "V", right = "N" } },
  { what = "plug", tag = "plug", ports = { down = "N" } },
  { what = "plug", tag = "plug", ports = { left = "N" } },
  { what = "plug", tag = "plug", ports = { right = "N" } },
}
local function gen()
  local W, H = 13, 9
  local g = {}
  for y = 1, H do g[y] = {} for x = 1, W do g[y][x] = (x == 1 or x == W or y == 1 or y == H) and "#" or "." end end
  local ledgeY = pick({ 5, 6, 7 })
  local ledgeW = rnd(2, 5)
  for x = 2, 1 + ledgeW do for y = ledgeY + 1, H - 1 do g[y][x] = "#" end end
  -- правая ступень (иногда)
  local rstep = rnd(0, 2)
  local rY = pick({ 6, 7 })
  for k = 0, rstep - 1 do for y = rY + 1, H - 1 do g[y][W - 1 - k] = "#" end end
  local objs, occ = {}, {}
  local function free(x, y) return g[y] and g[y][x] == "." and not occ[x .. "," .. y] end
  local function put(o) objs[#objs + 1] = o; occ[o.at[1] .. "," .. o.at[2]] = true end
  -- стояк S на уступе у левой стены, выход вправо В
  put({ kind = "source", at = { 2, ledgeY }, ports = { right = "V" } })
  -- полка: висячий блок
  local sx, sy = rnd(5, 11), rnd(2, 4)
  if g[sy + 1][sx] ~= "." then return nil end
  g[sy + 1][sx] = "#"
  if rnd() < 0.4 and g[sy + 1][sx + 1] == "." then g[sy + 1][sx + 1] = "#" end
  local P = pick(PIECES)
  put({ kind = "fitting", what = P.what, tag = "n", at = { sx, sy }, ports = P.ports })
  -- второй выход B (Н), иногда
  if rnd() < 0.7 then
    local cand = {}
    for x = 2, W - 1 do for y = 2, H - 1 do
      if free(x, y) and g[y + 1][x] == "#" then cand[#cand + 1] = { x, y } end end end
    local c = pick(cand)
    local dirs = {}
    for _, d in ipairs({ { "up", 0, -1 }, { "left", -1, 0 }, { "right", 1, 0 } }) do
      if free(c[1] + d[2], c[2] + d[3]) then dirs[#dirs + 1] = d[1] end end
    if #dirs == 0 then return nil end
    put({ kind = "source", at = c, ports = { [pick(dirs)] = "N" } })
  end
  -- ванна
  do
    local cand = {}
    for x = 4, W - 1 do for y = 2, H - 1 do
      if free(x, y) and (g[y + 1][x] == "#" or x == W - 1) then cand[#cand + 1] = { x, y } end end end
    local c = pick(cand)
    local dirs = {}
    for _, d in ipairs({ { "up", 0, -1 }, { "left", -1, 0 }, { "right", 1, 0 } }) do
      if free(c[1] + d[2], c[2] + d[3]) then dirs[#dirs + 1] = d[1] end end
    if #dirs == 0 then return nil end
    put({ kind = "fixture", what = "bath", at = c, ports = { [pick(dirs)] = pick({ "N", "V" }) } })
  end
  -- пробка на полу/уступе (иногда)
  if rnd() < 0.5 then
    local cand = {}
    for x = 3, W - 1 do for y = 2, H - 1 do
      if free(x, y) and g[y + 1][x] == "#" then cand[#cand + 1] = { x, y } end end end
    local c = pick(cand)
    local Q = pick(PIECES)
    put({ kind = "fitting", what = Q.what, tag = "p", at = c, ports = Q.ports })
  end
  -- Лапидус на полу, длина 2
  local cand = {}
  for x = 2, W - 2 do for y = 2, H - 1 do
    if free(x, y) and free(x + 1, y) and g[y + 1][x] == "#" and g[y + 1][x + 1] == "#" then cand[#cand + 1] = { x, y } end end end
  if #cand == 0 then return nil end
  local c = pick(cand)
  local lap = { kind = "lapidus", cells = { { c[1], c[2] }, { c[1] + 1, c[2] } }, head = pick({ 1, 2 }) }
  objs[#objs + 1] = lap
  local grid = {}
  for y = 1, H do grid[y] = table.concat(g[y]) end
  return { id = 8, flat = 8, name = "Брандспойт", length = { 2, pick({ 4, 5 }) }, pressure = pick({ 2, 3 }), grid = grid, objects = objs }
end
local function ascii(def)
  local rows = {}
  for y = 1, #def.grid do rows[y] = {} for x = 1, #def.grid[y] do rows[y][x] = def.grid[y]:sub(x, x) end end
  for _, o in ipairs(def.objects) do
    if o.kind == "lapidus" then for i, c in ipairs(o.cells) do rows[c[2]][c[1]] = (i == o.head) and "H" or "f" end
    else
      local ch = ({ source = "S", fixture = "K", fitting = o.tag or "b" })[o.kind] or "?"
      rows[o.at[2]][o.at[1]] = ch
    end
  end
  local t = {}
  for y = 1, #rows do t[y] = table.concat(rows[y]) end
  return table.concat(t, "/")
end
local function ser(def)
  local t = {}
  for _, o in ipairs(def.objects) do
    if o.kind == "lapidus" then t[#t + 1] = string.format("L(%d,%d)(%d,%d)h%d", o.cells[1][1], o.cells[1][2], o.cells[2][1], o.cells[2][2], o.head)
    else
      local ps = {}
      for k, v in pairs(o.ports) do ps[#ps + 1] = k .. "=" .. v end
      table.sort(ps)
      t[#t + 1] = string.format("%s:%s@%d,%d[%s]", o.kind, o.what or "", o.at[1], o.at[2], table.concat(ps, ","))
    end
  end
  return table.concat(t, " ")
end
local tried, ok = 0, 0
local c = { valid = 0, solv = 0, range = 0, hose = 0 }
for it = 1, N do
  local def = gen()
  if def then
    tried = tried + 1
    local okc, lvl = pcall(R.compile, def)
    if okc then
      local errs, warns = R.validate(lvl)
      if #errs == 0 and #warns == 0 then c.valid = c.valid + 1
        local G = SV.explore(lvl, 300000)
        if G and G.firstWin then c.solv = c.solv + 1
          local opt = G.depth[G.firstWin]
          local nwin = 0
          for i = 1, G.n do if G.flag[i] == 1 then nwin = nwin + 1 end end
          if opt >= 15 and opt <= 40 and nwin == 1 then c.range = c.range + 1
            local G2 = SV.explore(lvl, 300000, F.noHose)
            local hoseNeeded = G2 and not G2.firstWin
            SV.freeGraph(G2)
            if hoseNeeded then
              local good = SV.goodSet(G)
              local VL = V.compute(lvl, G, def, good)
              local m = V.measure(G, good, VL.newbie)
              ok = ok + 1
              fh:write(string.format("seed %d it %d | ход %d n %d жив %d СКР %.1f%% обез %.3f глуб %d [%s] | R%d L%d | %s | %s\n",
                seed, it, opt, G.n, m.live, m.hiddenPct, m.smart, m.maxDeep, m.deepList, def.pressure, def.length[2], ser(def), ascii(def)))
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
print(string.format("seed %d: сгенерировано %d, валидных %d, решаемых %d, в коридоре %d, годных %d", seed, tried, c.valid, c.solv, c.range, ok))
