-- build/l6c/a_f2plus/probe.lua файл.lua — разведка: какие одиночные правки стен дают скрытые ловушки на пути
-- после шага K (по умолчанию 4). Печатает только метрики и координаты правки.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local base = dofile(arg[1])
local K = tonumber(arg[2] or 4)
local function metrics(def)
  local ok, lvl = pcall(R.compile, def)
  if not ok then return nil end
  local errs = R.validate(lvl)
  if #errs > 0 then return nil end
  local G = SV.explore(lvl, 300000)
  if not G or not G.firstWin then if G then SV.freeGraph(G) end return nil end
  local good = SV.goodSet(G)
  local function lost(st)
    for q, p in ipairs(lvl.pieces) do if p.movable and st.pos[q] == 0 then return true end end
    return def.visibleLoss and def.visibleLoss(lvl, st) or false
  end
  local path, x = {}, G.firstWin
  while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
  table.insert(path, 1, 1)
  local late, early = 0, 0
  for k = 1, #path - 1 do
    local s = path[k]
    for e = G.eStart.p[s - 1], G.eStart.p[s] - 1 do
      local j = G.edges.p[e]
      if G.flag[j] ~= 2 and good[j] ~= 1 and not lost(R.decode(lvl, G.keys[j])) then
        if k - 1 >= K then late = late + 1 else early = early + 1 end
      end
    end
  end
  local res = { opt = G.depth[G.firstWin], n = G.n, late = late, early = early }
  SV.freeGraph(G); require("ffi").C.free(good)
  return res
end
local b = metrics(base)
print(string.format("база: ходов %d сост %d ранних %d поздних %d", b.opt, b.n, b.early, b.late))
local H, W = #base.grid, #base.grid[1]
for y = 2, H - 1 do for x = 2, W - 1 do
  local d = SV.deepcopy(base)
  local row = d.grid[y]
  local c = row:sub(x, x)
  local occupied = false
  for _, o in ipairs(d.objects) do
    if o.at and o.at[1] == x and o.at[2] == y then occupied = true end
    if o.cells then for _, cc in ipairs(o.cells) do if cc[1] == x and cc[2] == y then occupied = true end end end
  end
  if not occupied then
    d.grid[y] = row:sub(1, x - 1) .. (c == "#" and "." or "#") .. row:sub(x + 1)
    local m = metrics(d)
    if m and m.late > 0 then print(string.format("%s(%d,%d): ходов %d сост %d ранних %d поздних %d", c == "#" and "-стена" or "+стена", x, y, m.opt, m.n, m.early, m.late)) end
  end
end end
