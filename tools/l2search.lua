-- tools/l2search.lua — перебор вариантов квартиры 2 вокруг ядра (шахта, крючья, яма, коридор наверху):
-- открываемые клетки в зоне уступа и закутка + стартовые позиции героя. Печатает метрики, не решения.
package.path = "./?.lua;" .. package.path
local SV = require("solver.solve")
local base = { "#########", "##......#", "#...#####", "#...#????", "##...????", "##...####", "##...####", "##...####", "##...####", "#########" }
local Q = { { 6, 4 }, { 7, 4 }, { 8, 4 }, { 6, 5 }, { 7, 5 }, { 8, 5 } }
local function wallup(d)
  local keep = {}
  for _, o in ipairs(d.objects) do
    if o.tag == "hook" then
      local r = d.grid[o.at[2]]
      d.grid[o.at[2]] = r:sub(1, o.at[1] - 1) .. "#" .. r:sub(o.at[1] + 1)
    else keep[#keep + 1] = o end
  end
  d.objects = keep
end
local function mk(grid, cells)
  return { id = 2, flat = 2, name = "Скалолаз", length = { 2, 4 }, pressure = 0, grid = grid,
    objects = { { kind = "source", at = { 3, 2 }, ports = { right = "V" } }, { kind = "fixture", what = "toilet", at = { 8, 2 }, ports = { left = "N" } },
      { kind = "stub", tag = "hook", at = { 2, 3 }, ports = { right = "V" } }, { kind = "stub", tag = "hook", at = { 2, 4 }, ports = { right = "N" } },
      { kind = "lapidus", cells = cells, head = #cells } },
    ablations = { { name = "замурованы", mutate = wallup }, { name = "резьба", flip = "hook" } } }
end
local results, tried = {}, 0
for mask = 0, 2 ^ #Q - 1 do
  local g = {}
  for i, r in ipairs(base) do g[i] = r end
  local open = {}
  for b, c in ipairs(Q) do
    local ch = math.floor(mask / 2 ^ (b - 1)) % 2 == 1 and "." or "#"
    g[c[2]] = g[c[2]]:sub(1, c[1] - 1) .. ch .. g[c[2]]:sub(c[1] + 1)
    if ch == "." then open[#open + 1] = c end
  end
  g[5] = g[5]:sub(1, 8) .. "#"; g[4] = g[4]:sub(1, 8) .. "#"
  local zone = { { 5, 5 } }
  for _, c in ipairs(open) do zone[#zone + 1] = c end
  local inz = {}
  for _, c in ipairs(zone) do inz[c[1] * 100 + c[2]] = true end
  local starts = {}
  for _, a in ipairs(open) do
    for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
      local b = { a[1] + d[1], a[2] + d[2] }
      if inz[b[1] * 100 + b[2]] and not (b[1] == 5 and b[2] == 5) then
        starts[#starts + 1] = { a, b }
        for _, e in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
          local c3 = { b[1] + e[1], b[2] + e[2] }
          if inz[c3[1] * 100 + c3[2]] and not (c3[1] == a[1] and c3[2] == a[2]) and not (c3[1] == 5 and c3[2] == 5) then starts[#starts + 1] = { a, b, c3 } end
        end
      end
    end
  end
  for _, cells in ipairs(starts) do
    tried = tried + 1
    local d = mk(g, cells)
    local ok, res = pcall(SV.analyze, d, { cap = 50000 })
    if ok and res.solvable and res.minMoves >= 22 and res.minMoves <= 38 and res.deadPct >= 30 and res.falseBranches >= 2 and res.winStates == 1 then
      local ab = SV.ablations(d, { cap = 50000 })
      local good = true
      for _, x in ipairs(ab) do if x.solvable ~= false then good = false end end
      if good then
        local walls = 0
        for _ in (g[4] .. g[5]):gmatch("#") do walls = walls + 1 end
        results[#results + 1] = { m = res.minMoves, dead = res.deadPct, fb = res.falseBranches, st = res.states, g = { g[4], g[5] }, cells = cells, walls = walls }
      end
    end
  end
end
table.sort(results, function(a, b) if a.m ~= b.m then return a.m > b.m end return a.walls > b.walls end)
print(string.format("вариантов проверено: %d, прошли коридор и абляции: %d", tried, #results))
for i = 1, math.min(8, #results) do
  local r = results[i]
  local cs = {}
  for _, c in ipairs(r.cells) do cs[#cs + 1] = c[1] .. "," .. c[2] end
  print(string.format("%2d) ходов %d, тупиков %.1f%%, ложных веток %d, состояний %d | ряд4 %s ряд5 %s | старт %s", i, r.m, r.dead, r.fb, r.st, r.g[1], r.g[2], table.concat(cs, " ")))
end
