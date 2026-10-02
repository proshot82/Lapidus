-- build/l9v/pocket.lua файл.lua — что помечает карман 5 сверх кармана 4 (классы и где свободные детали). Только метрики.
local L = dofile("build/l9v/lib.lua")
local R, V = L.R, L.V
local S = L.load(arg[1], { pocket = 4 })
V.POCKET = 5
local VL5 = V.compute(S.lvl, S.G, S.def, S.good)
V.POCKET = 4
local agg, total = {}, 0
for i = 1, S.n do if S.flag[i] ~= 2 and not S.VL.newbie[i] and VL5.newbie[i] then
  total = total + 1
  local s = S:st(i)
  local parts = {}
  for q, p in ipairs(S.lvl.pieces) do if p.movable and not s.fixed[q] and s.pos[q] ~= 0 then
    local x, y = R.xy(S.lvl, s.pos[q]); parts[#parts+1] = string.format("%s(%d,%d)", p.tag, x, y) end end
  local k = (S:wet(s) and "мокро " or "сухо ") .. S:fixedSig(s) .. " || свободны: " .. table.concat(parts, " ")
  agg[k] = (agg[k] or 0) + 1
end end
print("карман 5 сверх 4 помечает состояний: " .. total)
local l = {}
for k, v in pairs(agg) do l[#l+1] = { k, v } end
table.sort(l, function(a, b) return a[2] > b[2] end)
for i = 1, math.min(15, #l) do print(string.format("  %6d  %s", l[i][2], l[i][1])) end
S:free()
