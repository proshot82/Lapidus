-- build/l4v3/walls.lua файл — замуровка по одной пустой клетке: решение (ходы, кратчайшие, ширина), абляции,
-- скрытые (автор / EP видим), глубина, двери с пути и со всех кратчайших. Без ходов.
package.path = "./?.lua;" .. package.path
local L = dofile("build/l4v3/lib.lua")
local SV = require("solver.solve")
local ST = require("solver.strict")
local function run(def)
  local R = require("core.rules")
  local lvl = R.compile(def)
  local errs = R.validate(lvl)
  if #errs > 0 then return "ошибка: " .. table.concat(errs, ";") end
  local A = L.load(def)
  if A.unsolvable then return string.format("НЕРЕШАЕМ (сост %d)", A.n or -1) end
  local cls = L.classes(A)
  local out = {}
  for _, mk in ipairs({ {}, { "EP" } }) do
    local M = L.mark(A, cls, mk)
    local m = A.V.measure(A.G, A.good, M)
    local H = L.hiddenOf(A, M)
    local sp, cl = {}, {}
    for _, d in ipairs(L.doors(A, H, false)) do sp[d.step] = true; cl[cls[L.classOf(A, cls, A.sts[d.to])][1]] = true end
    local spl, cll = {}, {}
    for s = 0, A.opt do if sp[s] then spl[#spl + 1] = s end end
    for k in pairs(cl) do cll[#cll + 1] = k end
    table.sort(cll)
    out[#out + 1] = string.format("%.1f%% гл%d дв[%s]%s", m.hiddenPct, m.maxDeep, table.concat(spl, ","), table.concat(cll, "+"))
  end
  local sx = ST.check(def, 3000000)
  local ab = {}
  for _, x in ipairs(SV.ablations(def, { cap = 3000000 })) do ab[#ab + 1] = (x.solvable == false) and "н" or "Р" end
  local s = string.format("ходов %d сост %d кратч %d шир %d абл %s | автор %s | EP видим %s", A.opt, A.G.n, sx.shortest, sx.maxWidth, table.concat(ab), out[1], out[2])
  L.free(A)
  return s
end
local file = arg[1]
local def0 = dofile(file)
local occ = {}
for _, o in ipairs(def0.objects) do
  if o.at then occ[o.at[1] .. "," .. o.at[2]] = true end
  if o.cells then for _, c in ipairs(o.cells) do occ[c[1] .. "," .. c[2]] = true end end
end
local function wall(d, cells)
  for _, c in ipairs(cells) do local x, y = c[1], c[2]; d.grid[y] = d.grid[y]:sub(1, x - 1) .. "#" .. d.grid[y]:sub(x + 1) end
  return d
end
print("исходный: " .. run(SV.deepcopy(def0))); io.flush()
for y = 1, #def0.grid do for x = 1, #def0.grid[1] do
  if def0.grid[y]:sub(x, x) == "." and not occ[x .. "," .. y] then
    io.write(string.format("стена (%d,%d): %s\n", x, y, run(wall(SV.deepcopy(def0), { { x, y } })))); io.flush()
  end
end end
