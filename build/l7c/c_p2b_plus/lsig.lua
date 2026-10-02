-- lsig.lua файл.lua [N] — перепись ЖИВЫХ состояний по подписям (как sig.lua): сколько живых на каждую конфигурацию
-- деталей (без положения Лапидуса) — чтобы видеть, где «раздувается» знаменатель доли скрытых. Только вывод инструмента.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local TOP = tonumber(arg[2] or 30)
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local P = lvl.pieces
local src; for q, p in ipairs(P) do if p.source then src = q end end
local sx = R.xy(lvl, P[src].start)
local function where(st, q)
  local c = st.pos[q]; if c == 0 then return "смыт" end
  local x, y = R.xy(lvl, c)
  local s = (x == sx) and ((st.fixed[q] and "F" or "столб") .. y) or (((x < sx) and "Л" or "П") .. x .. "," .. y)
  local m = {}
  for r, p2 in ipairs(P) do if r ~= q and p2.movable and st.pos[r] ~= 0 and not st.fixed[q] and not st.fixed[r] and st.asm[q] == st.asm[r] then m[#m + 1] = p2.tag end end
  if #m > 0 then s = s .. "+" .. table.concat(m) end
  return s
end
local cls, tot = {}, 0
for i = 1, G.n do
  if G.flag[i] == 0 and good[i] == 1 then
    local st = R.decode(lvl, G.keys[i])
    local t = {}
    for q, p in ipairs(P) do if p.movable then t[#t + 1] = p.tag .. ":" .. where(st, q) end end
    local k = table.concat(t, " ")
    cls[k] = (cls[k] or 0) + 1; tot = tot + 1
  end
end
local l = {}
for k, n in pairs(cls) do l[#l + 1] = { k = k, n = n } end
table.sort(l, function(a, b) return a.n > b.n end)
print("живых " .. tot .. ", конфигураций деталей " .. #l)
for i = 1, math.min(TOP, #l) do print(string.format("%6d  %s", l[i].n, l[i].k)) end
SV.freeGraph(G); require("ffi").C.free(good)
