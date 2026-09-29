-- pathnb.lua файл — для каждого шага кратчайшего пути: статусы соседей (live/hidden/visible/washed) — без порядка ходов.
package.path = "./?.lua;" .. package.path
local R = require("core.rules"); local SV = require("solver.solve"); local V = require("tools.vislib"); local MK = dofile("build/l2d/mk.lua")
local d = dofile(arg[1]); if d.rows then d = MK.build(d.rows, d.opts) end
local lvl = R.compile(d); local G = SV.explore(lvl, 3000000); local good = SV.goodSet(G); local VL = V.compute(lvl, G, d, good)
local path, x = {}, G.firstWin; while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end; table.insert(path, 1, 1)
local hid = {}
for i = 1, G.n do if G.flag[i] ~= 2 and good[i] ~= 1 and not VL.newbie[i] then hid[i] = true end end
local function depthFrom(j) local dd, q, h, maxd = { [j] = 0 }, { j }, 1, 0; while h <= #q do local u = q[h]; h = h + 1; for e = G.eStart.p[u-1], G.eStart.p[u]-1 do local v = G.edges.p[e]; if hid[v] and dd[v] == nil then dd[v] = dd[u]+1; if dd[v] > maxd then maxd = dd[v] end; q[#q+1] = v end end end; return maxd end
for k, s in ipairs(path) do
  local t = {}
  for e = G.eStart.p[s-1], G.eStart.p[s]-1 do local j = G.edges.p[e]
    local st = G.flag[j] == 2 and "смыт" or (good[j] == 1 and "жив" or (VL.newbie[j] and "вид" or ("СКРЫТ:" .. depthFrom(j))))
    t[#t+1] = st end
  local mv = k > 1 and R.moveName(G.pmove[s]):gsub("heel", "f"):gsub("head", "H"):gsub(":", ""):sub(1,3) or "start"
  print(k-1, mv, "|", table.concat(t, " "))
end
