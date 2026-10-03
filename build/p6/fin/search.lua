-- случайный поиск раскладок вокруг ядра «Крышка». luajit build/p6/fin/search.lua seed N
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local seed, N = tonumber(arg[1] or 1), tonumber(arg[2] or 200)
math.randomseed(seed)
local W, H = 16, 10
local function mk()
  local Rx = math.random(13, 15)
  local Ty = math.random(3, 6)
  local g = {}
  for y = 1, H do g[y] = {} for x = 1, W do g[y][x] = "#" end end
  for x = 2, 8 do g[9][x] = "." end
  g[10][9], g[10][10] = "~", "~"
  for y = Ty, 8 do for x = 9, Rx do g[y][x] = "." end end
  for x = 9, Rx do g[9][x] = "." end
  local nl = math.random(0, 3)
  for _ = 1, nl do
    local x, y = math.random(9, Rx), math.random(Ty + 1, 8)
    if not (y == 8 and (x == 9 or x == 10)) and not (x == 11 and y == 8) then g[y][x] = "#" end
  end
  if math.random() < 0.5 then g[8][11] = "#" end
  local function free(x, y) return g[y][x] == "." end
  local occ = {}
  local objs = {
    { kind = "fixture", what = "heater", at = { 2, 9 }, ports = { right = "V" } },
    { kind = "source", at = { 11, 9 }, ports = { left = "N" } },
  }
  occ["2,9"], occ["11,9"] = true, true
  -- Лапидус: горизонтально на полу справа или на уступе
  local lap
  for _ = 1, 50 do
    local y = math.random(Ty, 9)
    local x = math.random(9, Rx - 2)
    local ok = true
    for i = 0, 2 do if not free(x + i, y) or occ[(x + i) .. "," .. y] then ok = false end end
    if ok then
      local cells = { { x, y }, { x + 1, y }, { x + 2, y } }
      if math.random() < 0.5 then cells = { { x + 2, y }, { x + 1, y }, { x, y } } end
      lap = cells
      for i = 0, 2 do occ[(x + i) .. "," .. y] = true end
      break
    end
  end
  if not lap then return nil end
  local function place()
    for _ = 1, 100 do
      local x, y = math.random(9, Rx), math.random(Ty, 9)
      if free(x, y) and not occ[x .. "," .. y] and not (y == 9 and (x == 9 or x == 10)) then occ[x .. "," .. y] = true; return { x, y } end
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
-- фильтр «лазейка»: детали не свинчиваются между собой, пока не закреплены (ставятся по одной)
local function noPair(lvl, st, ns)
  local a, b = 3, 4
  if ns.pos[a] ~= 0 and ns.pos[b] ~= 0 and ns.asm[a] == ns.asm[b] and not ns.fixed[a] then return false end
  return true
end
local function ser(d)
  local o = {}
  for _, ob in ipairs(d.objects) do
    if ob.kind == "lapidus" then
      local c = {} for _, p in ipairs(ob.cells) do c[#c + 1] = "{" .. p[1] .. "," .. p[2] .. "}" end
      o[#o + 1] = string.format('{ kind = "lapidus", cells = { %s }, head = 1 }', table.concat(c, ","))
    else
      local p = {} for k, v in pairs(ob.ports or {}) do p[#p + 1] = k .. ' = "' .. v .. '"' end
      o[#o + 1] = string.format('{ kind = "%s", what = "%s", %sat = { %d, %d }, ports = { %s } }', ob.kind, ob.what or "", ob.tag and ('tag = "' .. ob.tag .. '", ') or "", ob.at[1], ob.at[2], table.concat(p, ", "))
    end
  end
  local g = {} for _, r in ipairs(d.grid) do g[#g + 1] = '    "' .. r .. '",' end
  return string.format('return {\n  id = 10, flat = 10, name = "%s", length = { %d, %d }, pressure = 0, tile = "mustard",\n  grid = {\n%s\n  },\n  objects = {\n    %s,\n  },\n}\n', d.name, d.length[1], d.length[2], table.concat(g, "\n"), table.concat(o, ",\n    "))
end
local found = 0
for t = 1, N do
  local d = mk()
  if d then
    local lvl = R.compile(d)
    local G = SV.explore(lvl, 300000)
    if G and G.firstWin then
      local mv, n = G.depth[G.firstWin], G.n
      SV.freeGraph(G)
      if mv >= 18 then
        local G2 = SV.explore(lvl, 300000, noPair)
        local loop = G2 and G2.firstWin
        if G2 then SV.freeGraph(G2) end
        if not loop then
          found = found + 1
          local name = string.format("build/p6/fin/srch/s%d_%d.lua", seed, t)
          d.name = name
          local f = io.open(name, "w"); f:write(ser(d)); f:close()
          print(string.format("%s ходов %d состояний %d", name, mv, n))
          io.stdout:flush()
        end
      end
    elseif G then SV.freeGraph(G) end
  end
end
