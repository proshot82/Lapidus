-- dbg.lua файл.lua — какие правила разметки (M.why) помечают живые состояния (отладка; вывод инструмента).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = dofile(os.getenv("VIS") or "build/l7c/c_p2b_plus/qvis.lua")
local def = dofile(arg[1])
local why = V.why(def, { adpStackVisible = true })
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local cnt, ex = {}, {}
for i = 1, G.n do
  if G.flag[i] == 0 and good[i] == 1 then
    local st = R.decode(lvl, G.keys[i])
    local w = why(lvl, st)
    if w then cnt[w] = (cnt[w] or 0) + 1; ex[w] = ex[w] or i end
  end
end
for w, n in pairs(cnt) do print(w, n) end
SV.freeGraph(G); require("ffi").C.free(good)
