-- build/l2k/hc2.lua seed.lua iters rndseed out.lua [box x1,y1,x2,y2] — мутатор ручного скелета, общий балл по воротам брифа.
-- Двигает стены внутри box, деталь, Лапидуса, крюки/стояк/прибор вдоль стен (порт смотрит в свободную клетку, за спиной стена).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local EV = dofile("build/l2k/ev2.lua")
local seedPath, iters, rs, outPath = arg[1], tonumber(arg[2] or 300), tonumber(arg[3] or 1), arg[4]
math.randomseed(rs)
local base = dofile(seedPath)
local W, H = #base.grid[1], #base.grid
local box = { 2, 2, W - 1, H - 1 }
if arg[5] then local t = {} for v in arg[5]:gmatch("%d+") do t[#t + 1] = tonumber(v) end box = t end
local DIRS = { up = { 0, -1 }, down = { 0, 1 }, left = { -1, 0 }, right = { 1, 0 } }
local DN = { "up", "down", "left", "right" }
local OPPN = { up = "down", down = "up", left = "right", right = "left" }
local function copy(d) return SV.deepcopy(d) end
local function occupied(d, skip)
  local o = {}
  for _, ob in ipairs(d.objects) do
    if ob ~= skip then
      if ob.kind == "lapidus" then for _, c in ipairs(ob.cells) do o[c[2] * 100 + c[1]] = true end
      else o[ob.at[2] * 100 + ob.at[1]] = true end
    end
  end
  return o
end
local function setc(d, x, y, ch) local r = d.grid[y]; d.grid[y] = r:sub(1, x - 1) .. ch .. r:sub(x + 1) end
local function getc(d, x, y) if x < 1 or y < 1 or x > W or y > H then return "#" end return d.grid[y]:sub(x, x) end
local function inbox(x, y) return x >= box[1] and x <= box[3] and y >= box[2] and y <= box[4] end
local function rndFree(d, skip)
  local occ = occupied(d, skip)
  for _ = 1, 200 do
    local x, y = math.random(box[1], box[3]), math.random(box[2], box[4])
    if getc(d, x, y) == "." and not occ[y * 100 + x] then return x, y end
  end
end
local function mutate(d)
  local r = math.random()
  if r < 0.45 then
    local x, y = math.random(box[1], box[3]), math.random(box[2], box[4])
    local occ = occupied(d)
    if occ[y * 100 + x] then return end
    local c = getc(d, x, y)
    if c == "#" then setc(d, x, y, ".") elseif c == "." then setc(d, x, y, "#") end
  elseif r < 0.62 then
    for _, ob in ipairs(d.objects) do if ob.kind == "fitting" then
      local x, y = rndFree(d, ob); if x then ob.at = { x, y } end
    end end
  elseif r < 0.75 then
    for _, ob in ipairs(d.objects) do if ob.kind == "lapidus" then
      local x, y = rndFree(d, ob); if not x then return end
      local cells = { { x, y } }
      local n = math.random(2, 3)
      local occ = occupied(d, ob)
      for k = 2, n do
        local p = cells[k - 1]
        local dd = DIRS[DN[math.random(4)]]
        local nx, ny = p[1] + dd[1], p[2] + dd[2]
        local dup = false
        for _, c in ipairs(cells) do if c[1] == nx and c[2] == ny then dup = true end end
        if dup or getc(d, nx, ny) ~= "." or occ[ny * 100 + nx] then return end
        cells[k] = { nx, ny }
      end
      ob.cells = cells; ob.head = #cells
    end end
  else
    -- закреплённый объект: новое место у стены
    local fixed = {}
    for _, ob in ipairs(d.objects) do if ob.kind == "stub" or ob.kind == "source" or ob.kind == "fixture" then fixed[#fixed + 1] = ob end end
    local ob = fixed[math.random(#fixed)]
    local occ = occupied(d, ob)
    for _ = 1, 100 do
      local x, y = math.random(box[1], box[3]), math.random(box[2], box[4])
      local dn = DN[math.random(4)]
      local v, b = DIRS[dn], DIRS[OPPN[dn]]
      if getc(d, x, y) == "." and not occ[y * 100 + x] and getc(d, x + v[1], y + v[2]) == "." and not occ[(y + v[2]) * 100 + x + v[1]]
        and getc(d, x + b[1], y + b[2]) ~= "." then
        local th; for _, t in pairs(ob.ports) do th = t end
        ob.at = { x, y }; ob.ports = { [dn] = th }
        return
      end
    end
  end
end
local function quick(d)
  local ok, lvl = pcall(R.compile, d)
  if not ok or #R.validate(lvl) > 0 then return nil end
  local s0 = R.newState(lvl)
  for q, p in ipairs(lvl.pieces) do if p.movable and s0.fixed[q] then return nil end end
  local G = SV.explore(lvl, 150000)
  if not G then return nil end
  local opt = G.firstWin and G.depth[G.firstWin]
  SV.freeGraph(G)
  return opt
end
local function score(d)
  local opt = quick(d)
  if not opt then return -10000, "нерешаем" end
  local s = - 15 * math.max(0, 14 - opt) - 15 * math.max(0, opt - 24)
  local abl = SV.ablations(d, { cap = 150000 })
  local nb = 0
  for _, a in ipairs(abl) do if a.solvable ~= false then s = s - 300; nb = nb + 1 end end
  if nb > 0 then return s - 100, "ход " .. opt .. " абл " .. nb end
  local r = EV.eval(d, 300000)
  if r.err or r.unsolvable then return -10000, "?" end
  s = s + math.min(r.hidPct, 40) - 3 * math.max(0, r.smart - 1) - 20 * math.max(0, (r.width or 9) - 3) + math.min(r.deep, 10) - 4 * math.max(0, r.walk - 6)
  return s, string.format("ход %d скр %.0f%% обез %.2f%% шир %s глуб %d сост %d прог %d", r.moves, r.hidPct, r.smart, tostring(r.width), r.deep, r.n, r.walk)
end
local cur = copy(base)
local cs, cl = score(cur)
local best, bs, bl = copy(cur), cs, cl
print("старт", cs, cl); io.stdout:flush()
for it = 1, iters do
  local nd = copy(cur)
  for _ = 1, math.random(1, 3) do mutate(nd) end
  local ns, nl = score(nd)
  if ns >= cs then cur, cs, cl = nd, ns, nl end
  if ns > bs then
    best, bs, bl = copy(nd), ns, nl; print(it, bs, bl); io.stdout:flush()
    if outPath then
      local t = { "-- hc2.lua из " .. seedPath .. ", балл " .. string.format("%.1f", bs) .. ": " .. bl, "local d = dofile(\"" .. seedPath .. "\")", "d.grid = {" }
      for _, row in ipairs(best.grid) do t[#t + 1] = "  \"" .. row .. "\"," end
      t[#t + 1] = "}"
      t[#t + 1] = "d.objects = {"
      for _, ob in ipairs(best.objects) do
        local parts = {}
        for k, v in pairs(ob) do
          if k == "cells" then local cs2 = {} for _, c in ipairs(v) do cs2[#cs2 + 1] = "{" .. c[1] .. "," .. c[2] .. "}" end parts[#parts + 1] = "cells={" .. table.concat(cs2, ",") .. "}"
          elseif k == "at" then parts[#parts + 1] = "at={" .. v[1] .. "," .. v[2] .. "}"
          elseif k == "ports" then local ps = {} for pk, pv in pairs(v) do ps[#ps + 1] = pk .. "=\"" .. pv .. "\"" end parts[#parts + 1] = "ports={" .. table.concat(ps, ",") .. "}"
          elseif type(v) == "string" then parts[#parts + 1] = k .. "=\"" .. v .. "\""
          else parts[#parts + 1] = k .. "=" .. tostring(v) end
        end
        t[#t + 1] = "  {" .. table.concat(parts, ", ") .. "},"
      end
      t[#t + 1] = "}"
      t[#t + 1] = "return d"
      local f = io.open(outPath, "w"); f:write(table.concat(t, "\n") .. "\n"); f:close()
    end
  end
end
print("лучший", bs, bl)
for _, row in ipairs(best.grid) do print("  " .. row) end
