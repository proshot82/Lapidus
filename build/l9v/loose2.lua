-- build/l9v/loose2.lua файл.lua "подпись класса" — точные клетки свободных деталей в скрытых состояниях класса
-- + сколько живых состояний имеют те же клетки деталей (чтобы понять, чем класс отличается от живых)
local L = dofile("build/l9v/lib.lua")
local S = L.load(arg[1])
local want = arg[2]
local agg, liveCfg = {}, {}
for i = 1, S.n do if S.flag[i] ~= 2 then
  local s = S:st(i)
  local k = (S:wet(s) and "мокро " or "сухо ") .. S:fixedSig(s)
  if k == want then
    local c = S:cfg(s)
    if S:hid(i) then agg[c] = (agg[c] or 0) + 1
    elseif S:live(i) then liveCfg[c] = (liveCfg[c] or 0) + 1 end
  end
end end
local l = {}
for k, v in pairs(agg) do l[#l+1] = { k, v } end
table.sort(l, function(a, b) return a[2] > b[2] end)
print("скрытых конфигураций деталей: " .. #l)
for i = 1, math.min(40, #l) do print(string.format("%6d скрытых | живых с той же раскладкой деталей %5d | %s", l[i][2], liveCfg[l[i][1]] or 0, l[i][1])) end
S:free()
