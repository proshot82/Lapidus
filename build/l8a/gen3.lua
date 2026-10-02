-- build/l8a/gen3.lua seed N out — разведка семейства «два крана + пробка на высокой полке» (авторская схема s8):
-- финал X → Лапидус → ванна K строится первым (валиден по резьбам), Q — лишний выход с пробкой; пробка ставится
-- на верх случайного висячего блока (высоко), добавляются 2–5 случайных блоков-уступов. Отбор: решаем, брандспойт
-- обязателен, 15–40 ходов, одна выигрышная; печать — метрики, двери с пути по половинам (хвост ≥ 8), раскладка.
-- Инструмент разведки: найденное доводится руками (LOG.md), решений не печатает.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local F = dofile("build/l8a/filt.lua")
local seed, N, outp = tonumber(arg[1] or 1), tonumber(arg[2] or 100), arg[3] or "build/l8a/out/gen3.txt"
math.randomseed(seed)
local rnd = math.random
local function pick(t) return t[rnd(#t)] end
local W, H = 13, 9
local VEC = { up = { 0, -1 }, right = { 1, 0 }, down = { 0, 1 }, left = { -1, 0 } }
local OPP = { up = "down", down = "up", left = "right", right = "left" }
local DN = { "up", "right", "down", "left" }
local fh = assert(io.open(outp, "a"))
local cnt = { gen = 0, solv = 0, range = 0, ok = 0 }
local function dirOf(a, b) for _, d in ipairs(DN) do if a[1] + VEC[d][1] == b[1] and a[2] + VEC[d][2] == b[2] then return d end end end
local function gen()
  local g = {}
  for y = 1, H do g[y] = {} for x = 1, W do g[y][x] = (x == 1 or x == W or y == 1 or y == H) and "#" or "." end end
  local lw = rnd(1, 4)
  local ly = rnd(3, 8)
  for x = 2, 1 + lw do for y = ly, H - 1 do g[y][x] = "#" end end
  for _ = 1, rnd(2, 5) do
    local bx, by, bw = rnd(3, W - 2), rnd(3, 7), rnd(1, 2)
    for xx = bx, math.min(W - 1, bx + bw - 1) do g[by][xx] = "#" end
  end
  local occ = {}
  local function free(x, y) return x >= 2 and x <= W - 1 and y >= 2 and y <= H - 1 and g[y][x] == "." and not occ[x .. "," .. y] end
  local objs = {}
  local function put(o) if not free(o.at[1], o.at[2]) then return false end occ[o.at[1] .. "," .. o.at[2]] = true; objs[#objs + 1] = o; return true end
  local L = rnd(3, 5)
  local sx, sy = rnd(2, W - 1), rnd(2, H - 1)
  if not free(sx, sy) then return nil end
  local path = { { sx, sy } }
  occ[sx .. "," .. sy] = "L"
  for _ = 2, L do
    local c = path[#path]
    local opts = {}
    for _, d in ipairs(DN) do local nx, ny = c[1] + VEC[d][1], c[2] + VEC[d][2]; if free(nx, ny) then opts[#opts + 1] = { nx, ny } end end
    if #opts == 0 then return nil end
    local n = pick(opts); path[#path + 1] = n; occ[n[1] .. "," .. n[2]] = "L"
  end
  local hd = dirOf(path[L - 1], path[L])
  local fd = dirOf(path[2], path[1])
  local X = { path[L][1] + VEC[hd][1], path[L][2] + VEC[hd][2] }
  local K = { path[1][1] + VEC[fd][1], path[1][2] + VEC[fd][2] }
  if not put({ kind = "source", at = X, ports = { [OPP[hd]] = "N" } }) then return nil end
  if not put({ kind = "fixture", what = "bath", at = K, ports = { [OPP[fd]] = "V" } }) then return nil end
  local tries = 0
  local Q, P, qd
  repeat
    tries = tries + 1
    if tries > 60 then return nil end
    local x, y = rnd(2, W - 1), rnd(2, H - 1)
    qd = pick(DN)
    local c = { x + VEC[qd][1], y + VEC[qd][2] }
    if free(x, y) and free(c[1], c[2]) and (g[y + 1][x] == "#" or g[y][x - 1] == "#" or g[y][x + 1] == "#") then Q, P = { x, y }, c end
  until Q
  put({ kind = "source", at = Q, ports = { [qd] = "V" } })
  local plug = { kind = "fitting", what = "plug", tag = "plug", at = P, ports = { [OPP[qd]] = "N" } }
  put(plug)
  local final = {}
  for _, o in ipairs(objs) do final[#final + 1] = o end
  final[#final + 1] = { kind = "lapidus", cells = path, head = L }
  local grid = {}
  for y = 1, H do grid[y] = table.concat(g[y]) end
  local fdef = { length = { 2, 5 }, pressure = 2, grid = grid, objects = final }
  local ok, flvl = pcall(R.compile, fdef)
  if not ok or #R.validate(flvl) > 0 then return nil end
  if not R.isWin(flvl, R.newState(flvl)) then return nil end
  occ[P[1] .. "," .. P[2]] = nil
  for _, c in ipairs(path) do occ[c[1] .. "," .. c[2]] = nil end
  local cand = {}
  for x = 2, W - 1 do for y = 2, 4 do if free(x, y) and g[y + 1][x] == "#" then cand[#cand + 1] = { x, y } end end end
  if #cand == 0 then return nil end
  plug.at = pick(cand)
  occ[plug.at[1] .. "," .. plug.at[2]] = true
  local lc = {}
  for x = 2, W - 2 do for y = 2, H - 1 do
    if free(x, y) and free(x + 1, y) and g[y + 1][x] == "#" and g[y + 1][x + 1] == "#" then lc[#lc + 1] = { x, y } end end end
  if #lc == 0 then return nil end
  local c = pick(lc)
  local start = {}
  for _, o in ipairs(objs) do start[#start + 1] = o end
  start[#start + 1] = { kind = "lapidus", cells = { { c[1], c[2] }, { c[1] + 1, c[2] } }, head = pick({ 1, 2 }) }
  return { id = 8, flat = 8, name = "Брандспойт", length = { 2, 5 }, pressure = pick({ 2, 2, 3 }), grid = grid, objects = start }
end
local function ascii(def)
  local rows = {}
  for y = 1, #def.grid do rows[y] = {} for x = 1, #def.grid[y] do rows[y][x] = def.grid[y]:sub(x, x) end end
  for _, o in ipairs(def.objects) do
    if o.kind == "lapidus" then for i, c in ipairs(o.cells) do rows[c[2]][c[1]] = (i == o.head) and "H" or "f" end
    else rows[o.at[2]][o.at[1]] = ({ source = "S", fixture = "K", fitting = "p" })[o.kind] end
  end
  local t = {} for y = 1, #rows do t[y] = table.concat(rows[y]) end
  return table.concat(t, "/")
end
local function ser(def)
  local t = {}
  for _, o in ipairs(def.objects) do
    if o.kind ~= "lapidus" then
      local ps = {} for k, v in pairs(o.ports) do ps[#ps + 1] = k .. "=" .. v end
      t[#t + 1] = string.format("%s@%d,%d[%s]", o.kind:sub(1, 3), o.at[1], o.at[2], table.concat(ps, ","))
    else t[#t + 1] = string.format("L%d,%d-%d,%d/h%d", o.cells[1][1], o.cells[1][2], o.cells[2][1], o.cells[2][2], o.head) end
  end
  return table.concat(t, " ")
end
for it = 1, N do
  local def = gen()
  if def then
    local ok, lvl = pcall(R.compile, def)
    if ok then
      local errs, warns = R.validate(lvl)
      if #errs == 0 and #warns == 0 then
        cnt.gen = cnt.gen + 1
        local G = SV.explore(lvl, 300000)
        if G and G.firstWin then
          cnt.solv = cnt.solv + 1
          local opt = G.depth[G.firstWin]
          local nwin = 0
          for i = 1, G.n do if G.flag[i] == 1 then nwin = nwin + 1 end end
          if opt >= 15 and opt <= 40 and nwin == 1 then
            cnt.range = cnt.range + 1
            local good = SV.goodSet(G)
            local VL = V.compute(lvl, G, def, good)
            local m = V.measure(G, good, VL.newbie)
            local ES, E = G.eStart.p, G.edges.p
            local half = { 0, 0 }
            for k = 1, #m.path - 1 do
              local s, best = m.path[k], 0
              for e = ES[s - 1], ES[s] - 1 do local j = E[e]
                if m.hidden[j] then
                  local dd, q, h, maxd = { [j] = 0 }, { j }, 1, 0
                  while h <= #q and maxd < 8 do local u = q[h]; h = h + 1
                    for e2 = ES[u - 1], ES[u] - 1 do local v = E[e2]; if m.hidden[v] and dd[v] == nil then dd[v] = dd[u] + 1; if dd[v] > maxd then maxd = dd[v] end; q[#q + 1] = v end end end
                  if maxd > best then best = maxd end
                end end
              if best >= 8 then local hh = ((k - 1) < (#m.path - 1) / 2) and 1 or 2; half[hh] = half[hh] + 1 end
            end
            require("ffi").C.free(good)
            if m.hiddenPct > 5 or half[1] + half[2] > 0 then
              local G2 = SV.explore(lvl, 300000, F.noHose)
              local need = G2 and not G2.firstWin
              SV.freeGraph(G2)
              if need then
                cnt.ok = cnt.ok + 1
                fh:write(string.format("s%d i%d | ход %d n %d R%d СКР %.1f%% обез %.3f двери %d/%d | %s | %s\n", seed, it, opt, G.n, def.pressure, m.hiddenPct, m.smart, half[1], half[2], ser(def), ascii(def)))
                fh:flush()
              end
            end
          end
        end
        SV.freeGraph(G)
      end
    end
  end
end
fh:close()
print(string.format("seed %d: валидных %d, решаемых %d, в коридоре %d, годных %d", seed, cnt.gen, cnt.solv, cnt.range, cnt.ok))
