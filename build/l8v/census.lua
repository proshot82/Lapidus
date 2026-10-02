-- build/l8v/census.lua файл.lua — скептик кв. 8: перепись достижимых состояний по классам:
-- положение каждой подвижной детали (клетка, закреплена ли), якоря Лапидуса (к какой детали прикручен какой конец),
-- включён ли брандспойт (один конец на мокром) и куда он бьёт; для каждого класса — живых / скрытых / видимых.
-- Печатает только классы и счётчики (без ходов).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local VL = V.compute(lvl, G, def, good)
local function pname(q) local p = lvl.pieces[q]; local x, y = p.x, p.y; return (p.tag or p.what or p.kind) .. "(" .. x .. "," .. y .. ")" end
local byPiece, byAnchor, byHose = {}, {}, {}
local function bump(t, k, i)
  local a = t[k] or { live = 0, hid = 0, vis = 0 }; t[k] = a
  if good[i] == 1 or G.flag[i] == 1 then a.live = a.live + 1 elseif VL.newbie[i] then a.vis = a.vis + 1 else a.hid = a.hid + 1 end
end
local hoseStates, hoseHits = 0, {}
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local st = R.decode(lvl, G.keys[i])
    local t = {}
    for q, p in ipairs(lvl.pieces) do if p.movable then
      if st.pos[q] == 0 then t[#t+1] = (p.tag or p.what) .. ":смыт" else
      local x, y = R.xy(lvl, st.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag or p.what, x, y, st.fixed[q] and "F" or "") end end end
    bump(byPiece, table.concat(t, " "), i)
    local w = R.water(lvl, st)
    local a = (w.headQ and ("голова→" .. pname(w.headQ)) or "голова свободна") .. " | " .. (w.heelQ and ("ноги→" .. pname(w.heelQ)) or "ноги свободны")
    bump(byAnchor, a, i)
    local hose = w.lapWet and ((w.headQ ~= nil) ~= (w.heelQ ~= nil))
    if hose then
      hoseStates = hoseStates + 1
      local jets = R.jets(lvl, st)
      for _, j in ipairs(jets) do if j.lapidus then
        local hit = "пусто"
        local piece = R.occupancy(st)
        for _, c in ipairs(j.cells) do local q = piece[c]; if q then local x, y = R.xy(lvl, c); hit = string.format("%s в (%d,%d)", lvl.pieces[q].tag or lvl.pieces[q].what, x, y) break end end
        local x, y = R.xy(lvl, j.cell)
        local k = string.format("%s из (%d,%d) %s, длина %d, попадание: %s", j.lapidus == "head" and "голова" or "ноги", x, y, R.DIRNAME[j.dir], #j.cells, hit)
        bump(byHose, k, i)
      end end
    end
  end
end
local function dump(title, t)
  print("== " .. title)
  local l = {}
  for k, a in pairs(t) do l[#l+1] = { k, a } end
  table.sort(l, function(a, b) return (a[2].live + a[2].hid + a[2].vis) > (b[2].live + b[2].hid + b[2].vis) end)
  for _, e in ipairs(l) do print(string.format("  %-60s живых %5d  скрытых %5d  видимых %5d", e[1], e[2].live, e[2].hid, e[2].vis)) end
end
dump("положение деталей", byPiece)
dump("якоря", byAnchor)
print("состояний с включённым брандспойтом: " .. hoseStates)
dump("струя свободного конца (класс: откуда, куда, что в струе)", byHose)
SV.freeGraph(G); require("ffi").C.free(good)
