-- перебор стартов в фиксированной рамке. luajit build/p6/fin/enum.lua рамка.lua Lmin Lmax [часть из частей: k K]
-- рамка: файл, возвращающий { grid = {...}, objects = {неподвижные} }; перебираются муфта, ниппель и Лапидус (прямой, длина 3)
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local frame = dofile(arg[1])
local Lmin, Lmax = tonumber(arg[2]), tonumber(arg[3])
local part, parts = tonumber(arg[4] or 1), tonumber(arg[5] or 1)
local H, W = #frame.grid, #frame.grid[1]
local fixedAt = {}
for _, o in ipairs(frame.objects) do fixedAt[o.at[1] .. "," .. o.at[2]] = true end
local function free(x, y) return x >= 1 and x <= W and y >= 1 and y <= H and frame.grid[y]:sub(x, x) == "." and not fixedAt[x .. "," .. y] end
local function solidBelow(x, y) local c = frame.grid[y + 1] and frame.grid[y + 1]:sub(x, x); return c == "#" or fixedAt[x .. "," .. (y + 1)] end
local cellsFree = {}
for y = 1, H do for x = 1, W do if free(x, y) and (frame.zone == nil or frame.zone(x, y)) then cellsFree[#cellsFree + 1] = { x, y } end end end
local laps = {}
for _, c in ipairs(cellsFree) do
  for _, dv in ipairs({ { 1, 0 }, { 0, -1 } }) do
    local cs, ok = {}, true
    for i = 0, 2 do local x, y = c[1] + dv[1] * i, c[2] + dv[2] * i; if not free(x, y) or not (frame.zone == nil or frame.zone(x, y)) then ok = false end; cs[#cs + 1] = { x, y } end
    if ok then laps[#laps + 1] = cs; laps[#laps + 1] = { cs[3], cs[2], cs[1] } end
  end
end
local function noPair(lvl, st, ns)
  if ns.pos[#ns.pos - 1] ~= 0 and ns.pos[#ns.pos] ~= 0 and ns.asm[#ns.pos - 1] == ns.asm[#ns.pos] and not ns.fixed[#ns.pos] then return false end
  return true
end
-- «по одной»: запрещено закрепление одной детали, пока другая не закреплена и не свинчена с ней
local function noSingle(lvl, st, ns)
  local a, b = #ns.pos - 1, #ns.pos
  if ns.pos[a] ~= 0 and ns.pos[b] ~= 0 and (ns.fixed[a] ~= ns.fixed[b]) then return false end
  return true
end
local cnt = 0
for li, lap in ipairs(laps) do
 if li % parts == part - 1 then
  local occ = {}
  for _, c in ipairs(lap) do occ[c[1] .. "," .. c[2]] = true end
  for _, cc in ipairs(cellsFree) do if not occ[cc[1] .. "," .. cc[2]] then
    for _, nn in ipairs(cellsFree) do if not occ[nn[1] .. "," .. nn[2]] and (nn[1] ~= cc[1] or nn[2] ~= cc[2]) then
      -- детали не должны стартовать свинченными и должны лежать (на стене, неподвижном или на Лапидусе)
      local adj = (nn[2] == cc[2] and math.abs(nn[1] - cc[1]) == 1)
      local function rests(p) local k = p[1] .. "," .. (p[2] + 1); return solidBelow(p[1], p[2]) or occ[k] end
      if not adj and rests(cc) and rests(nn) then
        local objs = {}
        for _, o in ipairs(frame.objects) do objs[#objs + 1] = o end
        objs[#objs + 1] = { kind = "fitting", what = "coupling", tag = "cpl", at = cc, ports = { left = "V", right = "V" } }
        objs[#objs + 1] = { kind = "fitting", what = "nipple", tag = "nip", at = nn, ports = { left = "N", right = "N" } }
        objs[#objs + 1] = { kind = "lapidus", cells = lap, head = 1 }
        local def = { id = 10, flat = 10, name = "e", length = { Lmin, Lmax }, pressure = 0, grid = frame.grid, objects = objs }
        local lvl = R.compile(def)
        local G = SV.explore(lvl, 400000)
        if G and G.firstWin and G.depth[G.firstWin] >= (frame.minMoves or 20) then
          local mv, n = G.depth[G.firstWin], G.n
          local good = SV.goodSet(G)
          -- первый шаг: доли и двери по половинам (мерка новичка)
          local VL = V.compute(lvl, G, def, good)
          local path, x = {}, G.firstWin
          while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
          table.insert(path, 1, 1)
          local h1, h2 = 0, 0
          for k = 1, #path - 1 do
            local s = path[k]
            for e = G.eStart.p[s - 1], G.eStart.p[s] - 1 do
              local j = G.edges.p[e]
              if G.flag[j] ~= 2 and good[j] ~= 1 and not VL.newbie[j] then if (k - 1) < (#path - 1) / 2 then h1 = h1 + 1 else h2 = h2 + 1 end break end
            end
          end
          SV.freeGraph(G); require("ffi").C.free(good)
          if (h1 > 0 and h2 > 0) or os.getenv("ALL") then
            local G2 = SV.explore(lvl, 400000, noPair)
            local singles = G2 and G2.firstWin and true or false
            if G2 then SV.freeGraph(G2) end
            local G3 = SV.explore(lvl, 400000, noSingle)
            local pairs = G3 and G3.firstWin and true or false
            if G3 then SV.freeGraph(G3) end
            local want = os.getenv("WANT") or "pair"
            if (want == "pair" and pairs and not singles) or (want == "single" and singles and not pairs) or want == "any" then
              cnt = cnt + 1
              print(string.format("%s%s ход %d сост %d двери %d/%d | cpl %d,%d nip %d,%d lap %d,%d;%d,%d;%d,%d", singles and "S" or "-", pairs and "P" or "-", mv, n, h1, h2, cc[1], cc[2], nn[1], nn[2], lap[1][1], lap[1][2], lap[2][1], lap[2][2], lap[3][1], lap[3][2]))
              io.stdout:flush()
            end
          end
        elseif G then SV.freeGraph(G) end
      end
    end end
  end end
 end
end
