-- build/l7j/q.lua файл.lua — быстрый замер: кратчайшее, состояний, выигрышных конфигураций (без решений)
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local errs = R.validate(lvl)
if #errs > 0 then print("ОШИБКИ: " .. table.concat(errs, "; ")) return end
local G = SV.explore(lvl, 3000000)
if not G then print("CAP") return end
local nwin, cfg = 0, {}
for i = 1, G.n do if G.flag[i] == 1 then nwin = nwin + 1; local st = R.decode(lvl, G.keys[i]); local kk = {}; for q = 1, #lvl.pieces do kk[#kk + 1] = st.pos[q] .. (st.fixed[q] and "f" or "") end; cfg[table.concat(kk, ",")] = true end end
local nc = 0 for _ in pairs(cfg) do nc = nc + 1 end
print(string.format("ходов %s | состояний %d | выигрышных %d (конфигураций деталей %d)", G.firstWin and G.depth[G.firstWin] or "НЕТ", G.n, nwin, nc))
