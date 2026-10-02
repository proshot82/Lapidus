-- build/l8a/cs1.lua out — перебор координат для авторской схемы «два крана» (только метрики, без решений):
-- A — выход В в левой стене (стартовый якорь), B — выход Н (финальный якорь), n — пробка для A на полке у колонки над A+1,
-- K — ванна (В). Отбор: решаем, брандспойт обязателен, 15–40 ходов, одна выигрышная; печать — метрики и раскладка.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local F = dofile("build/l8a/filt.lua")
local out = assert(io.open(arg[1] or "build/l8a/out/cs1.txt", "w"))
local D = { up = { 0, -1 }, right = { 1, 0 }, down = { 0, 1 }, left = { -1, 0 } }
local OPPN = { up = "down", down = "up", left = "right", right = "left" }
local W, H = 13, 9
local cnt = { tried = 0, solv = 0, ok = 0 }
local function build(rA, h, B, bdir, K, kdir, lap)
  local g = {}
  for y = 1, H do g[y] = {} for x = 1, W do g[y][x] = (x == 1 or x == W or y == 1 or y == H) and "#" or "." end end
  -- A на уступе-стене: под A стена до пола
  for y = rA + 1, H - 1 do g[y][2] = "#" end
  g[h + 1][4] = "#" -- полка
  local occ = {}
  local objs = {}
  local function put(o) local k = o.at[1] .. "," .. o.at[2]; if occ[k] or g[o.at[2]][o.at[1]] ~= "." then return false end occ[k] = true; objs[#objs + 1] = o; return true end
  if not put({ kind = "source", at = { 2, rA }, ports = { right = "V" } }) then return nil end
  if not put({ kind = "fitting", what = "plug", tag = "plug", at = { 4, h }, ports = { left = "N" } }) then return nil end
  if not put({ kind = "source", at = B, ports = { [bdir] = "N" } }) then return nil end
  if not put({ kind = "fixture", what = "bath", at = K, ports = { [kdir] = "V" } }) then return nil end
  for _, c in ipairs(lap) do if occ[c[1] .. "," .. c[2]] or g[c[2]][c[1]] ~= "." then return nil end end
  objs[#objs + 1] = { kind = "lapidus", cells = lap, head = 2 }
  local grid = {}
  for y = 1, H do grid[y] = table.concat(g[y]) end
  return { id = 8, flat = 8, name = "Брандспойт", length = { 2, 5 }, pressure = 2, grid = grid, objects = objs }
end
local function ascii(def)
  local rows = {}
  for y = 1, #def.grid do rows[y] = {} for x = 1, #def.grid[y] do rows[y][x] = def.grid[y]:sub(x, x) end end
  for _, o in ipairs(def.objects) do
    if o.kind == "lapidus" then for i, c in ipairs(o.cells) do rows[c[2]][c[1]] = (i == o.head) and "H" or "f" end
    else rows[o.at[2]][o.at[1]] = ({ source = "S", fixture = "K", fitting = "n" })[o.kind] end
  end
  local t = {} for y = 1, #rows do t[y] = table.concat(rows[y]) end
  return table.concat(t, "/")
end
local function dist(a, b) return math.abs(a[1] - b[1]) + math.abs(a[2] - b[2]) end
for rA = 4, 7 do
  local A1 = { 3, rA }
  for h = 2, rA - 2 do
    local noz = { 6, h }
    for bx = 3, W - 1 do for by = 2, H - 1 do for bdir, dv in pairs(D) do
      local B1 = { bx + dv[1], by + dv[2] }
      if B1[1] >= 2 and B1[1] <= W - 1 and B1[2] >= 2 and B1[2] <= H - 1 and dist(B1, A1) <= 4 and dist(B1, noz) <= 5 then
        for kx = 3, W - 1 do for ky = 2, H - 1 do for kdir, kv in pairs(D) do
          local K1 = { kx + kv[1], ky + kv[2] }
          if K1[1] >= 2 and K1[1] <= W - 1 and K1[2] >= 2 and K1[2] <= H - 1 and dist(K1, B1) <= 4 and dist(K1, B1) >= 2 then
            -- Лапидус на полу у A (длина 2), чтобы мог подняться к A
            local lap = { { 3, H - 1 }, { 4, H - 1 } }
            local def = build(rA, h, { bx, by }, bdir, { kx, ky }, kdir, lap)
            if def then
              local ok, lvl = pcall(R.compile, def)
              if ok then
                local errs, warns = R.validate(lvl)
                if #errs == 0 and #warns == 0 then
                  cnt.tried = cnt.tried + 1
                  local G = SV.explore(lvl, 200000)
                  if G and G.firstWin then
                    cnt.solv = cnt.solv + 1
                    local opt = G.depth[G.firstWin]
                    local nwin = 0
                    for i = 1, G.n do if G.flag[i] == 1 then nwin = nwin + 1 end end
                    if opt >= 15 and opt <= 40 and nwin == 1 then
                      local G2 = SV.explore(lvl, 200000, F.noHose)
                      local need = G2 and not G2.firstWin
                      SV.freeGraph(G2)
                      if need then
                        local good = SV.goodSet(G)
                        local VL = V.compute(lvl, G, def, good)
                        local m = V.measure(G, good, VL.newbie)
                        cnt.ok = cnt.ok + 1
                        out:write(string.format("ход %d n %d жив %d СКР %.1f%% обез %.3f глуб %d [%s] | %s\n", opt, G.n, m.live, m.hiddenPct, m.smart, m.maxDeep, m.deepList, ascii(def)))
                        out:flush()
                        require("ffi").C.free(good)
                      end
                    end
                  end
                  SV.freeGraph(G)
                end
              end
            end
          end
        end end end
      end
    end end end
  end
  io.stderr:write(string.format("rA %d: перебрано %d, решаемых %d, годных %d\n", rA, cnt.tried, cnt.solv, cnt.ok))
end
out:close()
