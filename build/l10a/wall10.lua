-- build/l9a/wall9.lua файл.lua [abl] — замуровка: по одной каждую пустую клетку (без деталей, стояка, приборов и тела)
-- заменить стеной и посчитать метрики; с abl — ещё и абляции (только когда оптимум не изменился). Результаты — построчно,
-- сразу в stdout (запускать в фоне с записью в файл). Решения не печатаются.
package.path = "./?.lua;" .. package.path
local L = dofile("build/l10a/lib10.lua")
local path = arg[1]
local withAbl = arg[2] == "abl"
local base = dofile(path)
local r0 = L.metrics(base, { abl = withAbl })
print("база: " .. L.fmt(r0)); io.stdout:flush()
local occ = {}
for _, o in ipairs(base.objects) do
  if o.at then occ[o.at[1] .. "," .. o.at[2]] = o.tag or o.what or o.kind end
  if o.cells then for _, c in ipairs(o.cells) do occ[c[1] .. "," .. c[2]] = "lap" end end
end
for y = 2, #base.grid - 1 do
  for x = 2, #base.grid[y] - 1 do
    if base.grid[y]:sub(x, x) == "." and not occ[x .. "," .. y] then
      local d = dofile(path)
      d.grid[y] = d.grid[y]:sub(1, x - 1) .. "#" .. d.grid[y]:sub(x + 1)
      local r = L.metrics(d, { abl = false })
      local tag = ""
      if r.solvable and r.opt == r0.opt then
        tag = " ← оптимум тот же"
        if withAbl then local ra = L.metrics(d, { abl = true }); r.ablSolv = ra.ablSolv; tag = tag .. ((ra.ablSolv == "") and ", абляции те же → МЁРТВАЯ?" or (", абляции: РЕШАЕМЫ [" .. ra.ablSolv .. "]")) end
      end
      print(string.format("(%d,%d): %s%s", x, y, L.fmt(r), tag)); io.stdout:flush()
    end
  end
end
print("готово")
