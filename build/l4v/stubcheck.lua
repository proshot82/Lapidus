-- build/l4v/stubcheck.lua — отвод (5,4) против стены: как размечены состояния «муфта над отводом» (без ходов).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local function run(def, label)
  local lvl = R.compile(def)
  local G = SV.explore(lvl, 3000000)
  local good = SV.goodSet(G)
  local VL = V.compute(lvl, G, def, good)
  local qc; for q, p in ipairs(lvl.pieces) do if p.what == "coupling" then qc = q end end
  local c53 = R.idx(lvl, 5, 3)
  local n, vis, hid, live, fx = 0, 0, 0, 0, 0
  for i = 1, G.n do if G.flag[i] ~= 2 then
    local st = VL.states[i]
    if st.pos[qc] == c53 then n = n + 1
      if st.fixed[qc] then fx = fx + 1 end
      if good[i] == 1 then live = live + 1 elseif VL.newbie[i] then vis = vis + 1 else hid = hid + 1 end end end end
  print(string.format("%-22s муфта в (5,3): %d сост. (закреплена %d) — живых %d, видимых %d, скрытых %d", label, n, fx, live, vis, hid))
end
local def = dofile("build/l4d/k29.lua")
run(def, "как есть (отвод)")
local d = SV.deepcopy(def)
for i, o in ipairs(d.objects) do if o.kind == "stub" and o.at[1] == 5 then table.remove(d.objects, i) break end end
d.grid[4] = d.grid[4]:sub(1, 4) .. "#" .. d.grid[4]:sub(6)
run(d, "отвод → стена")
