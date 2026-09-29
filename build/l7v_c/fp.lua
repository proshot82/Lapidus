-- build/l7v_c/fp.lua — сколько ЖИВЫХ состояний помечает каждое правило скептика (ложные срабатывания) и сколько
-- скрытых по файлу становятся видимыми; по конфигурациям деталей.
local M = dofile("build/l7v_c/lib.lua")
local R = M.R
local MK = dofile("build/l7v_c/marks.lua")
local def, lvl = M.load()
local G, good = M.graph(def, lvl)
local VL = M.V.compute(lvl, G, def, good)
local rules = { N1 = MK.N1, N2 = MK.N2, X1 = MK.X1 }
local names = { "N1", "N2", "X1" }
local fpLive, newVis, liveCfg = {}, {}, {}
for _, n in ipairs(names) do fpLive[n] = 0; newVis[n] = 0; liveCfg[n] = {} end
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local st = R.decode(lvl, G.keys[i])
    for _, n in ipairs(names) do
      if rules[n](lvl, st) then
        if good[i] == 1 then fpLive[n] = fpLive[n] + 1; local c = M.cfg(lvl, st); liveCfg[n][c] = (liveCfg[n][c] or 0) + 1
        elseif not VL.newbie[i] then newVis[n] = newVis[n] + 1 end
      end
    end
  end
end
for _, n in ipairs(names) do
  print(string.format("%s: живых помечено %d (ложные), скрытых по файлу переведено в видимые %d", n, fpLive[n], newVis[n]))
  local l = {}
  for c, v in pairs(liveCfg[n]) do l[#l + 1] = { c, v } end
  table.sort(l, function(a, b) return a[2] > b[2] end)
  for i = 1, math.min(8, #l) do print(string.format("    живое, помечено %s: %5d  %s", n, l[i][2], l[i][1])) end
end
