-- build/l9v2/one_abl.lua — контроль «один выход вверх» (g18_one.lua): чем решается без второго фонтана.
-- Только «решаем/нерешаем» и длина.
local L = dofile("build/l9v2/lib.lua")
local R, SV = L.R, L.SV
local F = dofile("build/l9a/filt.lua")
local F2 = dofile("build/l9a/filt2.lua")
local def = dofile("build/l9v2/g18_one.lua")
local lvl = R.compile(def)
local function noBodyLift(l, st, ns)
  if ns.dead then return true end
  local body = {}
  for _, c in ipairs(ns.body) do body[c] = true end
  for q, p in ipairs(l.pieces) do local c, c2 = st.pos[q], ns.pos[q]
    if p.movable and c ~= 0 and c2 ~= 0 and not ns.fixed[q] then
      local _, y1 = R.xy(l, c); local _, y2 = R.xy(l, c2)
      if y2 < y1 and body[l.nb[c2][R.DOWN]] then return false end end end
  return true
end
local plugUnused = function(l, st, ns) if ns.dead then return true end local q = F.find(l, "plug"); return ns.pos[q] == st.pos[q] or st.pos[q] ~= R.idx(l, 5, 5) and true or ns.pos[q] == R.idx(l, 5, 5) end
for _, f in ipairs({ { "без фильтра", nil }, { "Лапидус телом не поднимает деталь", noBodyLift }, { "стопки нет", F2.noStack },
  { "фонтан не держит", F.noHover }, { "не вдавить сверху", F.noPushDown } }) do
  local G = SV.explore(lvl, 3000000, f[2])
  print(string.format("  один выход вверх + %-36s %s", f[1], G.firstWin and ("решаем за " .. G.depth[G.firstWin]) or "нерешаем"))
  SV.freeGraph(G)
end
-- нужна ли заглушка вообще
local d2 = dofile("build/l9v2/g18_one.lua")
for i, o in ipairs(d2.objects) do if o.tag == "plug" then table.remove(d2.objects, i) break end end
local G = SV.explore(R.compile(d2), 3000000)
print("  один выход вверх, без заглушки: " .. (G.firstWin and ("решаем за " .. G.depth[G.firstWin]) or "нерешаем"))
SV.freeGraph(G)
