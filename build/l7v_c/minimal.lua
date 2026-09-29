-- build/l7v_c/minimal.lua — минимальность раскладки: по одной замуровываем пустые клетки и смотрим,
-- решаем ли уровень и какой стал оптимум (роль каждой клетки). Решения не печатаются.
local M = dofile("build/l7v_c/lib.lua")
local R = M.R
local def, lvl = M.load()
local occupied = {}
for _, o in ipairs(def.objects) do
  if o.kind == "lapidus" then for _, c in ipairs(o.cells) do occupied[c[1] .. "," .. c[2]] = true end
  else occupied[o.at[1] .. "," .. o.at[2]] = true end
end
local G0 = M.SV.explore(lvl, 3000000)
print(string.format("исходный: %d ходов, %d состояний", G0.depth[G0.firstWin], G0.n))
M.SV.freeGraph(G0)
for y = 1, lvl.H do
  for x = 1, lvl.W do
    if def.grid[y]:sub(x, x) == "." and not occupied[x .. "," .. y] then
      local d2 = M.SV.deepcopy(def)
      d2.ablations = nil
      d2.grid[y] = d2.grid[y]:sub(1, x - 1) .. "#" .. d2.grid[y]:sub(x + 1)
      local l2 = R.compile(d2)
      local errs = R.validate(l2)
      if #errs > 0 then print(string.format("(%d,%d) стена: %s", x, y, table.concat(errs, "; ")))
      else
        local G = M.SV.explore(l2, 3000000)
        if not G then print(string.format("(%d,%d) стена: CAP", x, y))
        elseif G.firstWin then print(string.format("(%d,%d) стена: РЕШАЕМ, %d ходов, %d состояний", x, y, G.depth[G.firstWin], G.n))
        else print(string.format("(%d,%d) стена: нерешаем (%d состояний)", x, y, G.n)) end
        if G then M.SV.freeGraph(G) end
      end
    end
  end
end
