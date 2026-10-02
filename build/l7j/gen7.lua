-- build/l7j/gen7.lua секунд seed — разведка механизмов для кв. 7: случайные чистые комнаты, 2 детали, без напора.
-- Отбирает раскладки, где в кратчайшем решении Лапидус толкает деталь, вися на окаменевшей детали (крюк-деталь).
-- Пишет кандидатов в build/l7j/gen/ (скелеты для ручной доводки). Решения не печатает.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local budget, seed = tonumber(arg[1] or 600), tonumber(arg[2] or 1)
local outdir = "build/l7j/gen"
os.execute("mkdir -p " .. outdir)
local rs = (seed * 7919 + 17) % 2147483647
local function rnd() rs = (rs * 16807) % 2147483647; return rs / 2147483647 end
local function rint(a, b) return a + math.floor(rnd() * (b - a + 1)) end
local function pick(t) return t[rint(1, #t)] end
local SIDES = { "up", "right", "down", "left" }
local DXY = { up = { 0, -1 }, right = { 1, 0 }, down = { 0, 1 }, left = { -1, 0 } }
local OPPS = { up = "down", down = "up", left = "right", right = "left" }
local function pieceTypes()
  local t = {}
  t[#t+1] = { what = "coupling", ports = { up = "V", down = "V" } }
  t[#t+1] = { what = "coupling", ports = { left = "V", right = "V" } }
  t[#t+1] = { what = "nipple", ports = { up = "N", down = "N" } }
  t[#t+1] = { what = "nipple", ports = { left = "N", right = "N" } }
  for _, a in ipairs({ { "down", "up" }, { "up", "down" }, { "left", "right" }, { "right", "left" } }) do
    t[#t+1] = { what = "adapter", ports = { [a[1]] = "V", [a[2]] = "N" } }
  end
  for _, c in ipairs({ { "down", "right" }, { "down", "left" }, { "up", "right" }, { "up", "left" } }) do
    for _, th in ipairs({ { "V", "N" }, { "N", "V" }, { "V", "V" }, { "N", "N" } }) do
      t[#t+1] = { what = "elbow", ports = { [c[1]] = th[1], [c[2]] = th[2] } }
    end
  end
  return t
end
local TYPES = pieceTypes()
local function portStr(p) local s = {} for _, k in ipairs(SIDES) do if p[k] then s[#s+1] = k .. ' = "' .. p[k] .. '"' end end return "{ " .. table.concat(s, ", ") .. " }" end
local function makeGrid(W, H)
  local g = {}
  for y = 1, H do g[y] = {} for x = 1, W do g[y][x] = (x == 1 or x == W or y == 1 or y == H) and "#" or "." end end
  local nf = rint(1, 4)
  for _ = 1, nf do
    local kind = rint(1, 4)
    if kind == 1 then -- полка
      local y, len = rint(3, H - 2), rint(1, 4); local x = rint(2, W - len)
      for k = 0, len - 1 do g[y][x + k] = "#" end
    elseif kind == 2 then -- столб
      local x, len = rint(2, W - 1), rint(1, 3); local y = rint(2, H - len)
      for k = 0, len - 1 do g[y + k][x] = "#" end
    elseif kind == 3 then -- ступень от пола
      local x, w, h = rint(2, W - 2), rint(1, 3), rint(1, 2)
      for yy = H - h, H - 1 do for xx = x, math.min(W - 1, x + w - 1) do g[yy][xx] = "#" end end
    else -- выступ от стены
      local y, len = rint(2, H - 2), rint(1, 3)
      if rnd() < 0.5 then for k = 0, len - 1 do g[y][2 + k] = "#" end else for k = 0, len - 1 do g[y][W - 1 - k] = "#" end end
    end
  end
  return g
end
local function free(g, x, y) return g[y] and g[y][x] == "." end
local function gen()
  local W, H = rint(8, 11), rint(7, 9)
  local g = makeGrid(W, H)
  local used = {}
  local function take(x, y) used[y * 100 + x] = true end
  local function ok(x, y) return free(g, x, y) and not used[y * 100 + x] end
  local objs = {}
  -- стояк: клетка у стены, выход в свободную клетку
  for _ = 1, 50 do
    local x, y = rint(2, W - 1), rint(2, H - 1)
    local side = pick({ "up", "up", "right", "left" })
    local d = DXY[side]
    if ok(x, y) and ok(x + d[1], y + d[2]) and not free(g, x, y + 1) then
      take(x, y); objs[#objs+1] = string.format('{ kind = "source", at = { %d, %d }, ports = { %s = "N" } }', x, y, side); break
    end
  end
  if #objs < 1 then return nil end
  for _ = 1, 50 do
    local x, y = rint(2, W - 1), rint(2, H - 2)
    local side = pick({ "left", "right", "down" })
    local d = DXY[side]
    local back = DXY[OPPS[side]]
    if ok(x, y) and ok(x + d[1], y + d[2]) and (not free(g, x + back[1], y + back[2]) or not free(g, x, y - 1)) then
      take(x, y); objs[#objs+1] = string.format('{ kind = "fixture", what = "sink", at = { %d, %d }, ports = { %s = "V" } }', x, y, side); break
    end
  end
  if #objs < 2 then return nil end
  local tags = { "p1", "p2" }
  for i = 1, 2 do
    for _ = 1, 80 do
      local x, y = rint(2, W - 1), rint(2, H - 1)
      if ok(x, y) and (not free(g, x, y + 1)) then
        local t = pick(TYPES)
        take(x, y); objs[#objs+1] = string.format('{ kind = "fitting", what = "%s", tag = "%s", at = { %d, %d }, ports = %s }', t.what, tags[i], x, y, portStr(t.ports)); break
      end
    end
  end
  if #objs < 4 then return nil end
  local Ls = pick({ { 2, 4 }, { 2, 5 }, { 3, 5 }, { 2, 3 } })
  for _ = 1, 80 do
    local x, y = rint(2, W - Ls[1]), rint(2, H - 1)
    local good = true
    for k = 0, Ls[1] - 1 do if not ok(x + k, y) or free(g, x + k, y + 1) then good = false end end
    if good then
      local cells = {} for k = 0, Ls[1] - 1 do cells[#cells+1] = string.format("{ %d, %d }", x + k, y) end
      objs[#objs+1] = string.format('{ kind = "lapidus", cells = { %s }, head = %d }', table.concat(cells, ", "), rnd() < 0.5 and 1 or Ls[1]); break
    end
  end
  if #objs < 5 then return nil end
  local rows = {}
  for y = 1, H do rows[y] = table.concat(g[y]) end
  return { rows = rows, objs = objs, L = Ls }
end
local function toSrc(c, name)
  local o = { "-- l7j " .. name .. ": скелет из build/l7j/gen7.lua (разведка механизма). Решение не пишется.",
    'local okV, vis = pcall(dofile, "build/l6j/vis.lua")', "return {", "  visibleLoss = okV and vis or nil,",
    string.format('  id = 7, flat = 7, name = "%s",', name),
    string.format('  length = { %d, %d }, pressure = 0, tile = "mint",', c.L[1], c.L[2]),
    "  target = { moves = { 15, 40 }, states = 100000, dead = 40, fb = 2 },", "  grid = {" }
  for _, r in ipairs(c.rows) do o[#o+1] = string.format('    "%s",', r) end
  o[#o+1] = "  },"; o[#o+1] = "  objects = {"
  for _, ob in ipairs(c.objs) do o[#o+1] = "    " .. ob .. "," end
  o[#o+1] = "  },"
  o[#o+1] = '  ablations = { { name = "без p1", remove = "p1" }, { name = "без p2", remove = "p2" } },'
  o[#o+1] = '  texts = { request = "", hints = { "", "", "" } },'
  o[#o+1] = "}"
  return table.concat(o, "\n") .. "\n"
end
local t0 = os.time()
local tried, kept = 0, 0
while os.time() - t0 < budget do
  local c = gen()
  if c then
    tried = tried + 1
    local src = toSrc(c, "g")
    local def = assert(load(src))()
    local okc, lvl = pcall(R.compile, def)
    if okc then
      local errs, warns = R.validate(lvl)
      if #errs == 0 and #warns == 0 then
        local G = SV.explore(lvl, 300000)
        if G and G.firstWin and G.depth[G.firstWin] >= 22 and G.depth[G.firstWin] <= 36 then
          local cfg, nc = {}, 0
          for i = 1, G.n do if G.flag[i] == 1 then local k = G.keys[i]:sub(-4); if not cfg[k] then cfg[k] = true; nc = nc + 1 end end end
          local win = R.decode(lvl, G.keys[G.firstWin])
          local bothUsed = win.pos[3] ~= 0 and win.fixed[3] and win.pos[4] ~= 0 and win.fixed[4]
          if nc == 1 and bothUsed then
            -- крюк-деталь: ход, при котором конец прикручен к окаменевшей фитинговой детали, а какая-то деталь сдвинулась
            local path, x = {}, G.firstWin
            while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
            table.insert(path, 1, 1)
            local hookPush = 0
            for k = 1, #path - 1 do
              local a, b = R.decode(lvl, G.keys[path[k]]), R.decode(lvl, G.keys[path[k + 1]])
              local piece = R.occupancy(a)
              local hk = false
              for _, w in ipairs({ "head", "heel" }) do
                local q = R.endScrew(lvl, a, piece, w)
                if q and lvl.pieces[q].movable then hk = true end
              end
              local moved = false
              for q = 3, #lvl.pieces do if a.pos[q] ~= b.pos[q] and not a.fixed[q] then moved = true end end
              if hk and moved then hookPush = hookPush + 1 end
            end
            if hookPush > 0 then
              local good = SV.goodSet(G)
              local VL = V.compute(lvl, G, def, good)
              local m = V.measure(G, good, VL.newbie)
              local h1, h2 = 0, 0
              for k = 1, #m.path - 1 do
                local s = m.path[k]
                for e = G.eStart.p[s - 1], G.eStart.p[s] - 1 do if m.hidden[G.edges.p[e]] then if (k - 1) < (#m.path - 1) / 2 then h1 = h1 + 1 else h2 = h2 + 1 end break end end
              end
              require("ffi").C.free(good)
              if m.hiddenPct >= 20 and m.maxDeep >= 6 and m.smart <= 0.5 then
                local abl = SV.ablations(def, { cap = 300000 })
                local narrow = true
                for _, a in ipairs(abl) do if a.solvable ~= false then narrow = false end end
                if narrow then
                  kept = kept + 1
                  local name = string.format("s%d_%d", seed, kept)
                  local f = io.open(outdir .. "/" .. name .. ".lua", "w"); f:write(toSrc(c, name)); f:close()
                  print(string.format("%s ходов %d сост %d скр %.0f%% обез %.2f глуб %d двери %d/%d крюк-толчков %d", name, m.opt, G.n, m.hiddenPct, m.smart, m.maxDeep, h1, h2, hookPush))
                  io.stdout:flush()
                end
              end
            end
          end
        end
        SV.freeGraph(G)
      end
    end
  end
end
print(string.format("перебрано %d, оставлено %d", tried, kept))
