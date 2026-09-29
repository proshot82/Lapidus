-- build/l2v2/combo.lua — k4: скрытые при замуровке сочетаний «лишних» крючьев и клеток. Без ходов.
package.path = "./?.lua;" .. package.path
local R = require("core.rules"); local SV = require("solver.solve")
local base = dofile("build/l2e/k4.lua")
local function wall(d, x, y)
  local keep = {}; for _, o in ipairs(d.objects) do if not (o.at and o.at[1] == x and o.at[2] == y) then keep[#keep + 1] = o end end
  d.objects = keep; d.grid[y] = d.grid[y]:sub(1, x - 1) .. "#" .. d.grid[y]:sub(x + 1)
end
local function run(name, cells)
  local d = SV.deepcopy(base); for _, c in ipairs(cells) do wall(d, c[1], c[2]) end
  local lvl = R.compile(d); local G = SV.explore(lvl, 3000000)
  if not G.firstWin then print(name .. ": нерешаем"); return end
  local good = SV.goodSet(G); local live, hid, hin = 0, 0, 0
  for i = 1, G.n do if G.flag[i] ~= 2 then local st = R.decode(lvl, G.keys[i])
    if good[i] == 1 then live = live + 1
      for e = G.eStart.p[i-1], G.eStart.p[i]-1 do local j = G.edges.p[e]
        if good[j] ~= 1 and base.hintError(lvl, st, R.decode(lvl, G.keys[j])) then hin = hin + 1 end end
    elseif not base.visibleLoss(lvl, st) then hid = hid + 1 end end end
  local ab = {}; for _, a in ipairs(SV.ablations(d, { cap = 3000000 })) do ab[#ab + 1] = a.solvable == false and "н" or "Р" end
  print(string.format("%-46s ходов %d, сост. %d, скрытых %d = %.1f %%, входов ошибки подсказки %d, абляции %s",
    name, G.depth[G.firstWin], G.n, hid, 100 * hid / (hid + live), hin, table.concat(ab)))
end
run("база", {})
run("без двух крючьев нижнего яруса", { { 7, 6 }, { 7, 7 } })
run("без крюка «под коридором»", { { 3, 7 } })
run("без (7,7) и «под коридором»", { { 7, 7 }, { 3, 7 } })
run("без (7,6) и «под коридором»", { { 7, 6 }, { 3, 7 } })
run("без всех трёх", { { 7, 6 }, { 7, 7 }, { 3, 7 } })
run("мёртвые клетки (4,2)(9,2)(4,3)(9,6)(6,9)", { { 4, 2 }, { 9, 2 }, { 4, 3 }, { 9, 6 }, { 6, 9 } })
run("то же + без двух нижних крючьев", { { 4, 2 }, { 9, 2 }, { 4, 3 }, { 9, 6 }, { 6, 9 }, { 7, 6 }, { 7, 7 } })
