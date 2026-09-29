-- build/l7v_d/gates.lua — сводка ворот по разметкам (файл, карман, широкий новичок, знаток без D, знаток) одним прогоном,
-- по общей линейке tools/vislib.lua (те же формулы, что в build/l6b/check.lua). Без ходов.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local base = dofile("build/l7c/d_tee_lift/L7D.lua")
local lvl = R.compile(base)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local variants = {
  { "файл (L7D.lua)", base.visibleLoss },
  { "новичок + карман (v_pocket)", dofile("build/l7v_d/v_pocket.lua").visibleLoss },
  { "новичок широкий (v_wide)", dofile("build/l7v_d/v_wide.lua").visibleLoss },
  { "знаток без D (v_expert_noD)", dofile("build/l7v_d/v_expert_noD.lua").visibleLoss },
  { "знаток (v_expert)", dofile("build/l7v_d/v_expert.lua").visibleLoss },
}
for _, v in ipairs(variants) do
  local def = SV.deepcopy(base); def.visibleLoss = v[2]
  local VL = V.compute(lvl, G, def, good)
  local M = V.measure(G, good, VL.newbie)
  local EX = V.measure(G, good, VL.expert)
  print(string.format("%-32s СКРЫТЫХ %.0f %% (%d/%d) | ОБЕЗЬЯНА %.2f %% | ГЛУБИНА %d у пути [%s] | знаток-линейка %.0f %%",
    v[1], M.hiddenPct, M.hid, M.hid + M.live, M.smart, M.maxDeep, M.deepList, EX.hiddenPct))
end
SV.freeGraph(G); require("ffi").C.free(good)
