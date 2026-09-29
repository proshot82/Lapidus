-- width.lua файл.lua — где кратчайшие решения расходятся: по глубинам — сколько состояний лежит на кратчайших путях
-- и чем они различаются (клетки Лапидуса и деталей). Только вывод инструмента.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local E, ES = G.edges.p, G.eStart.p
local opt = G.depth[G.firstWin]
local on = {}
for i = 1, G.n do if G.flag[i] == 1 and G.depth[i] == opt then on[i] = true end end
for i = G.n, 1, -1 do
  if not on[i] and G.flag[i] == 0 and G.depth[i] < opt then
    for e = ES[i - 1], ES[i] - 1 do local j = E[e]; if on[j] and G.depth[j] == G.depth[i] + 1 then on[i] = true; break end end
  end
end
local byD = {}
for i = 1, G.n do if on[i] then local d = G.depth[i]; byD[d] = byD[d] or {}; table.insert(byD[d], i) end end
for d = 0, opt do
  local l = byD[d] or {}
  if #l > 1 then
    local t = {}
    for _, i in ipairs(l) do
      local st = R.decode(lvl, G.keys[i])
      local b = {}
      for _, c in ipairs(st.body) do local x, y = R.xy(lvl, c); b[#b + 1] = x .. "," .. y end
      local p = {}
      for q, pp in ipairs(lvl.pieces) do if pp.movable then local x, y = R.xy(lvl, st.pos[q]); p[#p + 1] = pp.tag:sub(1, 1) .. x .. "," .. y end end
      t[#t + 1] = "[" .. table.concat(b, " ") .. " | " .. table.concat(p, " ") .. "]"
    end
    print(d .. ": " .. #l .. "  " .. table.concat(t, "  "))
  end
end
SV.freeGraph(G)
