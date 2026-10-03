-- быстрый замер: решаемость, ходов, состояний (без ворот). luajit build/p6/fin/ev.lua файл...
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
for i = 1, #arg do
  local ok, def = pcall(dofile, arg[i])
  if not ok then print(arg[i], "ERR", def) else
    local lvl = R.compile(def)
    local G = SV.explore(lvl, 3000000)
    if not G then print(arg[i], "CAP") else
      print(string.format("%-40s %s ходов %s состояний %d", arg[i], G.firstWin and "реш" or "НЕРЕШ", G.firstWin and G.depth[G.firstWin] or "-", G.n))
      SV.freeGraph(G)
    end
  end
end
