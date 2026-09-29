-- build/l2v3/cmp02.lua — правило видимости k6 («больше ни к чему не прикрутится»), применённое к levels/02.lua. Без ходов.
package.path = "./?.lua;" .. package.path
local R = require("core.rules"); local SV = require("solver.solve")
local k6 = dofile("build/l2e/k6.lua"); local d = dofile("levels/02.lua"); local lvl = R.compile(d)
local G = SV.explore(lvl, 3000000); local good = SV.goodSet(G)
local live, vis, hid = 0, 0, 0
for i = 1, G.n do if G.flag[i] ~= 2 then if good[i] == 1 then live = live + 1 else
  if k6.visibleLoss(lvl, R.decode(lvl, G.keys[i])) then vis = vis + 1 else hid = hid + 1 end end end end
print(string.format("levels/02 по правилу k6: живых %d, видимых %d, скрытых %d = %.1f %%", live, vis, hid, 100 * hid / (hid + live)))
