-- перебор: одна деталь (муфта) и Лапидус; ниппель задан в рамке. luajit enum1.lua рамка Lmin Lmax
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local frame = dofile(arg[1])
local Lmin, Lmax = tonumber(arg[2]), tonumber(arg[3])
local H, W = #frame.grid, #frame.grid[1]
local fixedAt = {}
for _, o in ipairs(frame.objects) do fixedAt[o.at[1] .. "," .. o.at[2]] = true end
local function free(x, y) return x >= 1 and x <= W and y >= 1 and y <= H and frame.grid[y]:sub(x, x) == "." and not fixedAt[x .. "," .. y] end
local cellsFree = {}
for y = 1, H do for x = 1, W do if free(x, y) and frame.zone(x, y) then cellsFree[#cellsFree + 1] = { x, y } end end end
local laps = {}
for _, c in ipairs(cellsFree) do
  for _, dv in ipairs({ { 1, 0 }, { 0, -1 } }) do
    local cs, ok = {}, true
    for i = 0, 2 do local x, y = c[1] + dv[1] * i, c[2] + dv[2] * i; if not free(x, y) or not frame.zone(x, y) then ok = false end; cs[#cs + 1] = { x, y } end
    if ok then laps[#laps + 1] = cs; laps[#laps + 1] = { cs[3], cs[2], cs[1] } end
  end
end
for _, lap in ipairs(laps) do
  local occ = {}
  for _, c in ipairs(lap) do occ[c[1] .. "," .. c[2]] = true end
  for _, cc in ipairs(cellsFree) do if not occ[cc[1] .. "," .. cc[2]] then
    local objs = {}
    for _, o in ipairs(frame.objects) do objs[#objs + 1] = o end
    objs[#objs + 1] = { kind = "fitting", what = "coupling", tag = "cpl", at = cc, ports = { left = "V", right = "V" } }
    objs[#objs + 1] = { kind = "lapidus", cells = lap, head = 1 }
    local def = { id = 10, flat = 10, name = "e", length = { Lmin, Lmax }, pressure = 0, grid = frame.grid, objects = objs }
    local lvl = R.compile(def)
    local G = SV.explore(lvl, 400000)
    if G and G.firstWin and G.depth[G.firstWin] >= frame.minMoves then
      print(string.format("ход %d сост %d | cpl %d,%d lap %d,%d;%d,%d;%d,%d", G.depth[G.firstWin], G.n, cc[1], cc[2], lap[1][1], lap[1][2], lap[2][1], lap[2][2], lap[3][1], lap[3][2]))
      io.stdout:flush()
    end
    if G then SV.freeGraph(G) end
  end end
end
