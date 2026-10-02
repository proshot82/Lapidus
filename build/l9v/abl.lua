-- build/l9v/abl.lua файл.lua — узость абляций и несущность ошибок.
-- 1) для каждого фильтра абляции/контроля: доля состояний базового графа, которые он запрещает (как ns), и сколько
--    состояний кратчайших путей он режет; 2) более узкие варианты абляций; 3) несущность: уровень с запретом каждой
--    ошибки — решаем? насколько легче (умная обезьяна по линейке, наобум, скрытых). Только метрики.
local L = dofile("build/l9v/lib.lua")
local R, V, SV = L.R, L.V, L.SV
local ST = require("solver.strict")
local F = dofile("build/l9a/filt.lua")
local path = arg[1]
local def = dofile(path)
local S = L.load(def)
local lvl = S.lvl
local W = lvl.W
local function idx(x, y) return (y - 1) * W + x end
local sp = S:onShortest()
local tee, plug = F.find(lvl, "tee"), F.find(lvl, "plug")
-- узкие варианты
local N = {}
-- «не едет»: запрещён переход, в котором свободная деталь, стоявшая на гребне (в st), сдвинулась по горизонтали
N.noRideMove = function(l, st, ns)
  if ns.dead then return true end
  local _, top = F.columns(l, st)
  for q, p in ipairs(l.pieces) do
    local c, c2 = st.pos[q], ns.pos[q]
    if p.movable and c ~= 0 and not st.fixed[q] and top[c] and c2 ~= 0 then
      local x1, y1 = R.xy(l, c); local x2, y2 = R.xy(l, c2)
      if x1 ~= x2 then return false end
    end
  end
  return true
end
-- «не вдавить»: запрещён переход, в котором деталь закрепилась на выходе гребёнки, пока сеть мокрая (в st)
N.noScrewWet = function(l, st, ns)
  if ns.dead then return true end
  if not F.wet(l, st) then return true end
  for q, p in ipairs(l.pieces) do if p.movable and p.tag ~= "nip" and ns.fixed[q] and not st.fixed[q] then
    local x, y = R.xy(l, ns.pos[q]); if y == 6 and (x == 7 or x == 8) then return false end end end
  return true
end
-- «не переезжает с гребня на гребень»: свободная деталь не переходит из (7,4) в (8,4) (и обратно) — без второго фонтана
N.noCrestToCrest = function(l, st, ns)
  if ns.dead then return true end
  for q, p in ipairs(l.pieces) do
    local c, c2 = st.pos[q], ns.pos[q]
    if p.movable and c ~= 0 and c2 ~= 0 and not st.fixed[q] and ((c == idx(7, 4) and c2 == idx(8, 4)) or (c == idx(8, 4) and c2 == idx(7, 4))) then return false end
  end
  return true
end
-- «деталь не проходит над выходами»: свободная деталь не бывает в клетках (7,1..5),(8,1..5) — над гребёнкой
N.noOverComb = function(l, st, ns)
  if ns.dead then return true end
  for q, p in ipairs(l.pieces) do local c = ns.pos[q]
    if p.movable and c ~= 0 and not ns.fixed[q] then local x, y = R.xy(l, c); if (x == 7 or x == 8) and y <= 5 then return false end end end
  return true
end
local filters = {
  { "абл: фонтан не держит (noHover)", F.noHover },
  { "абл: не едет по гребням (noRide)", F.noRide },
  { "абл: не вдавить сверху (noPushDown)", F.noPushDown },
  { "узк: с гребня не сдвинуть вбок", N.noRideMove },
  { "узк: с гребня на гребень нельзя", N.noCrestToCrest },
  { "узк: на мокрый выход не прикрутить", N.noScrewWet },
  { "узк: над гребёнкой деталям нельзя", N.noOverComb },
  { "контр: не трогать детали всухую", F.dryHandsOff },
  { "контр: заглушка не на отвод (9,7)", F.notAt("plug", 9, 7) },
  { "контр: заглушка не в ближний (7,6)", F.notAt("plug", 7, 6) },
  { "контр: тройник не в фонтаны", function(l, st, ns) return F.notAt("tee", 7, 6)(l, st, ns) and F.notAt("tee", 8, 6)(l, st, ns) end },
  { "контр: обе ошибки пути запрещены", function(l, st, ns) return F.dryHandsOff(l, st, ns) and F.notAt("plug", 7, 6)(l, st, ns) end },
}
print("фильтр | запрещает рёбер базового графа (доля) | режет ходов кратчайших путей (шаги) | с фильтром: решаем? ходов, состояний, скрытых %, умная обезьяна %")
for _, f in ipairs(filters) do
  local name, flt = f[1], f[2]
  local cut, tot, cutSp, steps = 0, 0, 0, {}
  local dw = S:distWin()
  for i = 1, S.n do if S.flag[i] == 0 then
    local s = S:st(i)
    for e = S.ES[i-1], S.ES[i]-1 do local j = S.E[e]
      tot = tot + 1
      if not flt(lvl, s, S:st(j)) then cut = cut + 1
        if sp[i] and sp[j] and dw[j] == dw[i] - 1 then cutSp = cutSp + 1; steps[#steps+1] = S.G.depth[i] end end
    end end end
  table.sort(steps)
  local G2 = SV.explore(R.compile(def), 3000000, flt)
  local res
  if not G2.firstWin then res = string.format("НЕРЕШАЕМ (n=%d)", G2.n)
  else
    local good2 = SV.goodSet(G2)
    local VL2 = V.compute(lvl, G2, def, good2)
    local m = V.measure(G2, good2, VL2.newbie)
    res = string.format("решаем: ходов %d, n=%d, скрытых %.1f %%, обезьяна %.3f %%", G2.depth[G2.firstWin], G2.n, m.hiddenPct, m.smart)
    require("ffi").C.free(good2)
  end
  SV.freeGraph(G2)
  print(string.format("  %-40s | %6d (%4.1f %%) | %d [%s] | %s", name, cut, 100 * cut / tot, cutSp, table.concat(steps, ","), res))
  io.stdout:flush()
end
S:free()
