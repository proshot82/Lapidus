-- build/l2e/wallup.lua файл.lua — «замуровка» (ворота 30.09): жадно замуровываем пустые клетки, без которых не меняются
-- длина кратчайшего решения и исходы абляций (решаем/нерешаем), и считаем скрытые тупики после этого. Только метрики.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local EV = dofile("build/l2e/ev.lua")
local file = arg[1]
local function load() return dofile(file) end
local function sig(def)
  local ok, lvl = pcall(R.compile, def); if not ok then return nil end
  if #R.validate(lvl) > 0 then return nil end
  local G = SV.explore(lvl, 3000000); if not G or not G.firstWin then if G then SV.freeGraph(G) end; return nil end
  local s = { G.depth[G.firstWin] }; SV.freeGraph(G)
  for _, a in ipairs(SV.ablations(def, { cap = 3000000 })) do s[#s + 1] = a.solvable == false and "x" or "o" end
  return table.concat(s, ",")
end
local base = load()
local s0 = sig(base)
print("база: подпись (ходы, абляции) = " .. s0)
local walled = {}
local grid = {}
for i, r in ipairs(base.grid) do grid[i] = r end
local function occupied(x, y)
  for _, o in ipairs(base.objects) do
    if o.at and o.at[1] == x and o.at[2] == y then return true end
    if o.cells then for _, c in ipairs(o.cells) do if c[1] == x and c[2] == y then return true end end end
  end
  return false
end
local changed = true
while changed do
  changed = false
  for y = 1, #grid do for x = 1, #grid[1] do
    if grid[y]:sub(x, x) == "." and not occupied(x, y) then
      local d = load()
      for i, r in ipairs(grid) do d.grid[i] = r end
      d.grid[y] = d.grid[y]:sub(1, x - 1) .. "#" .. d.grid[y]:sub(x + 1)
      if sig(d) == s0 then grid[y] = d.grid[y]; walled[#walled + 1] = string.format("(%d,%d)", x, y); changed = true end
    end
  end end
end
print("замуровано клеток: " .. #walled .. "  " .. table.concat(walled, " "))
for _, r in ipairs(grid) do print("  " .. r) end
local d = load(); for i, r in ipairs(grid) do d.grid[i] = r end
local r = EV.eval(d, nil, true, true)
print(string.format("после замуровки: ходов %d, состояний %d, живых %d, скрытых %d = %.0f %% (перевёрн. %.0f %%), глубина %d",
  r.opt, r.n, r.live, r.n - r.live - r.washed, r.pctAuthor, r.pctFlip, r.deep))
