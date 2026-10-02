-- build/l9v/loose.lua файл.lua — где лежат свободные детали в скрытых состояниях каждого класса (метрики, без кадров)
local L = dofile("build/l9v/lib.lua")
local S = L.load(arg[1])
local R = L.R
local agg = {}
local function zone(x, y)
  if y == 8 then return "нижняя комната (ряд 8)" end
  if x == 2 and (y == 6 or y == 7) then return "левая шахта" end
  if x == 9 and y >= 4 and y <= 7 then return "правая шахта" end
  if y <= 4 then return "верх (ряды 2–4)" end
  if y == 5 then return "карниз/ряд 5" end
  if y == 6 then return "ряд 6 (столбы)" end
  return string.format("(%d,%d)", x, y)
end
for i = 1, S.n do if S:hid(i) then
  local s = S:st(i)
  local k = (S:wet(s) and "мокро " or "сухо ") .. S:fixedSig(s)
  local parts = {}
  for q, p in ipairs(S.lvl.pieces) do if p.movable and not s.fixed[q] and s.pos[q] ~= 0 then
    local x, y = R.xy(S.lvl, s.pos[q]); parts[#parts+1] = p.tag .. ": " .. zone(x, y) end end
  local kk = k .. " || " .. table.concat(parts, "; ")
  agg[kk] = (agg[kk] or 0) + 1
end end
local l = {}
for k, v in pairs(agg) do l[#l+1] = { k, v } end
table.sort(l, function(a, b) return a[2] > b[2] end)
for i = 1, math.min(60, #l) do print(string.format("%6d  %s", l[i][2], l[i][1])) end
S:free()
