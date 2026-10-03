-- build/p6/neck/search.lua seed count W H — случайный поиск раскладок с подписью темы (вдохновение; уровни доводятся руками)
package.path = "./?.lua;" .. package.path
local L = require("build.p6.neck.lib")
local seed, count, W, H = tonumber(arg[1] or 1), tonumber(arg[2] or 200), tonumber(arg[3] or 10), tonumber(arg[4] or 7)
local mode = arg[5] or "elbow"
math.randomseed(seed)
local DIRS = { "up", "right", "down", "left" }
local DX = { up = 0, right = 1, down = 0, left = -1 }
local DY = { up = -1, right = 0, down = 1, left = 0 }
local function gen()
  local g = {}
  for y = 1, H do g[y] = {} for x = 1, W do g[y][x] = (x == 1 or y == 1 or x == W or y == H) and "#" or ((math.random() < 0.58) and "." or "#") end end
  local function open(x, y) return x >= 1 and y >= 1 and x <= W and y <= H and g[y][x] == "." end
  local used = {}
  local function key(x, y) return x .. "," .. y end
  local function freeCell(needFloor)
    for _ = 1, 200 do
      local x, y = math.random(2, W - 1), math.random(2, H - 1)
      if open(x, y) and not used[key(x, y)] and (not needFloor or g[y + 1][x] == "#") then return x, y end
    end
  end
  local objs = {}
  -- источник и прибор: клетка с портом в сторону открытой клетки
  local function fixedWithPort(kind, what, th)
    for _ = 1, 200 do
      local x, y = freeCell(false)
      if not x then return nil end
      local d = DIRS[math.random(4)]
      local nx, ny = x + DX[d], y + DY[d]
      if open(nx, ny) and not used[key(nx, ny)] then
        used[key(x, y)] = true
        return { kind = kind, what = what, at = { x, y }, ports = { [d] = th } }, d
      end
    end
  end
  local s = fixedWithPort("source", nil, "N"); if not s then return end
  local f = fixedWithPort("fixture", "toilet", math.random() < 0.5 and "V" or "N"); if not f then return end
  objs[#objs + 1] = s; objs[#objs + 1] = f
  local npieces = (mode == "two") and 2 or 1
  for k = 1, npieces do
    local x, y = freeCell(true); if not x then return end
    used[key(x, y)] = true
    local ports = {}
    local d1 = DIRS[math.random(4)]
    local d2
    repeat d2 = DIRS[math.random(4)] until d2 ~= d1
    ports[d1] = math.random() < 0.5 and "V" or "N"
    ports[d2] = math.random() < 0.5 and "V" or "N"
    objs[#objs + 1] = { kind = "fitting", what = "elbow", tag = (k == 1) and "a" or "b", at = { x, y }, ports = ports }
  end
  -- Лапидус: 3 клетки пути, хотя бы одна на полу
  for _ = 1, 200 do
    local x, y = freeCell(false)
    if x then
      local cells = { { x, y } }
      local ok = true
      local seen = { [key(x, y)] = true }
      for i = 2, 3 do
        local c = cells[#cells]
        local cand = {}
        for _, d in ipairs(DIRS) do local nx, ny = c[1] + DX[d], c[2] + DY[d]; if open(nx, ny) and not used[key(nx, ny)] and not seen[key(nx, ny)] then cand[#cand + 1] = { nx, ny } end end
        if #cand == 0 then ok = false break end
        local n = cand[math.random(#cand)]
        cells[#cells + 1] = n; seen[key(n[1], n[2])] = true
      end
      if ok then
        local floor = false
        for _, c in ipairs(cells) do if g[c[2] + 1][c[1]] == "#" then floor = true end end
        if floor then
          objs[#objs + 1] = { kind = "lapidus", cells = cells, head = (math.random() < 0.5) and 1 or 3 }
          local rows = {}
          for yy = 1, H do rows[yy] = table.concat(g[yy]) end
          local lmin = 3
          local lmax = math.random(4, 6)
          return { id = 99, flat = 6, name = "rnd", length = { lmin, lmax }, pressure = 0, grid = rows, objects = objs }
        end
      end
    end
  end
end
local function ser(def)
  local o = {}
  o[#o + 1] = "return {\n  id = 99, flat = 6, name = \"rnd\", length = { " .. def.length[1] .. ", " .. def.length[2] .. " }, pressure = 0, tile = \"mint\",\n  grid = {\n"
  for _, r in ipairs(def.grid) do o[#o + 1] = "    \"" .. r .. "\",\n" end
  o[#o + 1] = "  },\n  objects = {\n"
  for _, ob in ipairs(def.objects) do
    if ob.kind == "lapidus" then
      local cs = {}
      for _, c in ipairs(ob.cells) do cs[#cs + 1] = "{ " .. c[1] .. ", " .. c[2] .. " }" end
      o[#o + 1] = "    { kind = \"lapidus\", cells = { " .. table.concat(cs, ", ") .. " }, head = " .. ob.head .. " },\n"
    else
      local ps = {}
      for _, d in ipairs(DIRS) do if ob.ports[d] then ps[#ps + 1] = d .. " = \"" .. ob.ports[d] .. "\"" end end
      o[#o + 1] = string.format("    { kind = %q,%s%s at = { %d, %d }, ports = { %s } },\n", ob.kind, ob.what and (" what = \"" .. ob.what .. "\",") or "", ob.tag and (" tag = \"" .. ob.tag .. "\",") or "", ob.at[1], ob.at[2], table.concat(ps, ", "))
    end
  end
  o[#o + 1] = "  },\n}\n"
  return table.concat(o)
end
local found = 0
for i = 1, count do
  local def = gen()
  if def then
    local ok, r = pcall(L.eval, def, 150000)
    if ok and r.opt and r.opt >= 14 and r.smart <= 3 and r.nwin <= 3 and r.intoRP >= 20 then
      found = found + 1
      local name = string.format("build/p6/neck/rnd/s%d_%d.lua", seed, i)
      local fh = io.open(name, "w"); fh:write(ser(def)); fh:close()
      print(name .. ": " .. L.line(r))
      io.stdout:flush()
    end
  end
end
