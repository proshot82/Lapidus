-- flt.lua файл.lua [имя_фильтра ...] — решаемость и длина кратчайшего решения с фильтрами ходов (без решений).
-- Фильтры: nohose (запрещены состояния «Лапидус мокрый, один конец свободен»), а также ablations из файла по имени.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local F = {}
F.nohose = function(lvl, st, ns)
  local w = R.status(lvl, ns)
  if w.lapWet and not w.win and (w.headQ == nil or w.heelQ == nil) then return false end
  return true
end
for _, ab in ipairs(def.ablations or {}) do if ab.filter then F[ab.name] = ab.filter end end
local names = {}
for i = 2, #arg do names[#names + 1] = arg[i] end
local function combined(lvl, st, ns)
  for _, n in ipairs(names) do if not F[n](lvl, st, ns) then return false end end
  return true
end
local G = SV.explore(lvl, 3000000, (#names > 0) and combined or nil)
if not G then print("CAP") return end
print(string.format("[%s] состояний %d, %s", table.concat(names, "+"), G.n, G.firstWin and ("решаем за " .. G.depth[G.firstWin]) or "НЕРЕШАЕМ"))
SV.freeGraph(G)
