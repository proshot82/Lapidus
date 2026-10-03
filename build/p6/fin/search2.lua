-- компактный поиск вокруг ядра «Крышка»: luajit build/p6/fin/search2.lua seed N W H
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local seed, N = tonumber(arg[1] or 1), tonumber(arg[2] or 200)
local W, H = tonumber(arg[3] or 13), tonumber(arg[4] or 7)
math.randomseed(seed)
local FL = H - 1 -- ряд трубы / пола
local function mk()
  local tubeLen = math.random(3, 5)
  local mx = 2 + tubeLen          -- клетка-устье
  local d1, d2, sx = mx + 1, mx + 2, mx + 3
  if sx > W - 2 then return nil end
  local Ty = math.random(2, FL - 2)
  local g = {}
  for y = 1, H do g[y] = {} for x = 1, W do g[y][x] = "#" end end
  for x = 2, W - 1 do g[FL][x] = "." end
  g[H][d1], g[H][d2] = "~", "~"
  for y = Ty, FL - 1 do for x = d1, W - 1 do g[y][x] = "." end end
  local nl = math.random(0, 4)
  for _ = 1, nl do
    local x, y = math.random(d1, W - 1), math.random(Ty + 1, FL)
    if not (x == d1 or x == d2) and not (x == sx and y == FL) then g[y][x] = "#" end
  end
  if math.random() < 0.5 then g[FL - 1][sx] = "#" end
  -- иногда — одиночный слив на правом полу
  if math.random() < 0.3 then local x = math.random(sx + 1, W - 1); if g[FL][x] == "." then g[H][x] = "~" end end
  local function free(x, y) return g[y][x] == "." end
  local occ = { [2 .. "," .. FL] = true, [sx .. "," .. FL] = true }
  local objs = {
    { kind = "fixture", what = "heater", at = { 2, FL }, ports = { right = "V" } },
    { kind = "source", at = { sx, FL }, ports = { left = "N" } },
  }
  local lap
  for _ = 1, 60 do
    local y = math.random(Ty, FL)
    local x = math.random(d1, W - 3)
    local vertical = math.random() < 0.3
    local cells = {}
    local ok = true
    for i = 0, 2 do
      local cx, cy = vertical and x or x + i, vertical and y - i or y
      if cy < 1 or not free(cx, cy) or occ[cx .. "," .. cy] then ok = false end
      cells[#cells + 1] = { cx, cy }
    end
    if ok then
      if math.random() < 0.5 then cells = { cells[3], cells[2], cells[1] } end
      lap = cells
      for _, c in ipairs(cells) do occ[c[1] .. "," .. c[2]] = true end
      break
    end
  end
  if not lap then return nil end
  local function place()
    for _ = 1, 100 do
      local x, y = math.random(d1, W - 1), math.random(Ty, FL)
      if free(x, y) and not occ[x .. "," .. y] and not (y == FL and (x == d1 or x == d2)) then occ[x .. "," .. y] = true; return { x, y } end
    end
  end
  local c, n = place(), place()
  if not c or not n then return nil end
  objs[#objs + 1] = { kind = "fitting", what = "coupling", tag = "cpl", at = c, ports = { left = "V", right = "V" } }
  objs[#objs + 1] = { kind = "fitting", what = "nipple", tag = "nip", at = n, ports = { left = "N", right = "N" } }
  objs[#objs + 1] = { kind = "lapidus", cells = lap, head = 1 }
  local grid = {}
  for y = 1, H do grid[y] = table.concat(g[y]) end
  return { id = 10, flat = 10, name = "s", length = { math.random(2, 3), math.random(5, 6) }, pressure = 0, tile = "mustard", grid = grid, objects = objs }
end
local function noPair(lvl, st, ns)
  if ns.pos[3] ~= 0 and ns.pos[4] ~= 0 and ns.asm[3] == ns.asm[4] and not ns.fixed[3] then return false end
  return true
end
local function ser(d)
  local o = {}
  for _, ob in ipairs(d.objects) do
    if ob.kind == "lapidus" then
      local c = {} for _, p in ipairs(ob.cells) do c[#c + 1] = "{ " .. p[1] .. ", " .. p[2] .. " }" end
      o[#o + 1] = string.format('{ kind = "lapidus", cells = { %s }, head = 1 }', table.concat(c, ", "))
    else
      local p = {} for _, k in ipairs({ "up", "right", "down", "left" }) do local v = ob.ports and ob.ports[k]; if v then p[#p + 1] = k .. ' = "' .. v .. '"' end end
      o[#o + 1] = string.format('{ kind = "%s", %s%sat = { %d, %d }, ports = { %s } }', ob.kind, ob.what and ('what = "' .. ob.what .. '", ') or "", ob.tag and ('tag = "' .. ob.tag .. '", ') or "", ob.at[1], ob.at[2], table.concat(p, ", "))
    end
  end
  local g = {} for _, r in ipairs(d.grid) do g[#g + 1] = '    "' .. r .. '",' end
  return string.format('return {\n  id = 10, flat = 10, name = "%s", length = { %d, %d }, pressure = 0, tile = "mustard",\n  grid = {\n%s\n  },\n  objects = {\n    %s,\n  },\n}\n', d.name, d.length[1], d.length[2], table.concat(g, "\n"), table.concat(o, ",\n    "))
end
for t = 1, N do
  local d = mk()
  if d then
    local lvl = R.compile(d)
    local G = SV.explore(lvl, 200000)
    if G and G.firstWin then
      local mv, n = G.depth[G.firstWin], G.n
      SV.freeGraph(G)
      if mv >= 20 then
        local G2 = SV.explore(lvl, 200000, noPair)
        local loop = (not G2) or G2.firstWin
        if G2 then SV.freeGraph(G2) end
        if not loop then
          local name = string.format("build/p6/fin/srch/c%d_%d.lua", seed, t)
          d.name = name
          local f = io.open(name, "w"); f:write(ser(d)); f:close()
          print(string.format("%s ходов %d состояний %d", name, mv, n))
          io.stdout:flush()
        end
      end
    elseif G then SV.freeGraph(G) end
  end
end
