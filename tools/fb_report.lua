-- tools/fb_report.lua — разбор ложных веток кандидата БЕЗ печати решения: для каждой тупиковой области
-- (≥ 50 состояний) рядом с оптимальным путём — что случилось (заглушка смыта/застряла, тройник не там…).
-- luajit tools/fb_report.lua файл.lua [N]
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local list = dofile(arg[1])
local def = list[tonumber(arg[2] or "1")] or list
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
local function describe(k)
  local st = R.decode(lvl, k)
  local t = {}
  for q, p in ipairs(lvl.pieces) do
    if p.movable then
      local w = p.what or p.kind
      if st.pos[q] == 0 then t[#t + 1] = w .. ":смыт"
      else local px, py = R.xy(lvl, st.pos[q]); t[#t + 1] = string.format("%s:(%d,%d)%s", w, px, py, st.fixed[q] and "fix" or "") end
    end
  end
  return table.concat(t, " ")
end
local cats, total = {}, 0
for i = 1, #path - 1 do
  local s = path[i]
  local here = describe(G.keys[s])
  for e = G.eStart.p[s - 1], G.eStart.p[s] - 1 do
    local t = G.edges.p[e]
    if good[t] == 0 and G.flag[t] ~= 2 then
      local big = SV.regionAtLeast(G, t, 50)
      local d = describe(G.keys[t])
      local key = ((d == here) and "только Лапидус (застрял/не туда)" or d) .. (big and "  [≥50]" or "  [<50]")
      cats[key] = (cats[key] or 0) + 1
      if big then total = total + 1 end
    end
  end
end
print(string.format("состояний %d, мин. ходов %d, входов в ложные ветки %d", G.n, #path - 1, total))
for k, v in pairs(cats) do print(string.format("  %2d × %s", v, k)) end
