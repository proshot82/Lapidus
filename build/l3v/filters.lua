-- build/l3v/filters.lua [файл уровня] — контрольные фильтры (должны оставаться решаемыми) и дополнительные
-- абляции роли (проверка, какие приёмы ещё обязательны, кроме перечисленных в уровне).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1] or "levels/03.lua")
local lvl = R.compile(def)
local function soapQ(lvl) local t = {}; for q, p in ipairs(lvl.pieces) do if p.porcelain then t[#t + 1] = q end end; return t end
local SQ = soapQ(lvl)
local function xy(c) return R.xy(lvl, c) end
local function bodySet(st) local b = {}; for _, c in ipairs(st.body) do b[c] = true end; return b end

local F = {}
-- контроли (ожидаем: решаем)
F[#F + 1] = { name = "К1 мыло влево не толкать", ctrl = true, f = function(lvl, st, ns)
  for _, q in ipairs(SQ) do if st.pos[q] ~= 0 and ns.pos[q] ~= 0 and ns.pos[q] == lvl.nb[st.pos[q]][4] then return false end end
  return true end }
F[#F + 1] = { name = "К2 ноги не заходят в нишу (2,6)", ctrl = true, f = function(lvl, st, ns)
  local x, y = xy(ns.body[1]); return not (x == 2 and y == 6) end }
F[#F + 1] = { name = "К3 голова не ходит, пока мыло лежит на Лапидусе", ctrl = true, f = function(lvl, st, ns)
  local b = bodySet(st)
  local held = false
  for _, q in ipairs(SQ) do local c = st.pos[q]; if c ~= 0 and b[lvl.nb[c][3]] then held = true end end
  if not held then return true end
  -- ход головой: новая клетка головы не из старого тела (растяжение/скольжение) либо сжатие при неподвижных ногах
  local old = bodySet(st)
  local isHead = (not old[ns.body[#ns.body]]) or (#ns.body < #st.body and ns.body[1] == st.body[1])
  return not isHead
end }
F[#F + 1] = { name = "К4 подъём по шахте ногами вперёд запрещён", ctrl = true, f = function(lvl, st, ns)
  local hx, hy = xy(ns.body[1]); local gx, gy = xy(ns.body[#ns.body])
  return not (hx == 7 and hy >= 2 and hy <= 6 and hy < gy) end }
-- дополнительные абляции (интересно, обязательны ли)
F[#F + 1] = { name = "А1 мыло не лежит на голове", ctrl = false, f = function(lvl, st, ns)
  local head = ns.body[#ns.body]
  for _, q in ipairs(SQ) do local c = ns.pos[q]; if c ~= 0 and lvl.nb[c][3] == head then return false end end
  return true end }
F[#F + 1] = { name = "А2 мыло не лежит на середине тела (не на конце)", ctrl = false, f = function(lvl, st, ns)
  local b = bodySet(ns); local head, heel = ns.body[#ns.body], ns.body[1]
  for _, q in ipairs(SQ) do local c = ns.pos[q]; if c ~= 0 then local d = lvl.nb[c][3]; if b[d] and d ~= head and d ~= heel then return false end end end
  return true end }
F[#F + 1] = { name = "А3 Лапидус не занимает низ шахты (7,7)", ctrl = false, f = function(lvl, st, ns)
  for _, c in ipairs(ns.body) do local x, y = xy(c); if x == 7 and y == 7 then return false end end
  return true end }
F[#F + 1] = { name = "А4 длина не больше 4, пока мыло не на ступеньке", ctrl = false, f = function(lvl, st, ns)
  local step = (7 - 1) * lvl.W + 7
  for _, q in ipairs(SQ) do if ns.pos[q] == step then return true end end
  return #ns.body <= 4 end }
F[#F + 1] = { name = "А5 сжатий нет", ctrl = false, f = function(lvl, st, ns) return #ns.body >= #st.body end }
F[#F + 1] = { name = "А6 мыло не поднимается выше ряда 5 после старта", ctrl = false, f = function(lvl, st, ns)
  for _, q in ipairs(SQ) do local c = ns.pos[q]; if c ~= 0 and c ~= lvl.pieces[q].start then local x, y = xy(c); if y <= 5 and not (x == 4 and y == 4) then return false end end end
  return true end }
F[#F + 1] = { name = "А7 мыло не выше ряда 4 (лифт только на одну клетку)", ctrl = false, f = function(lvl, st, ns)
  for _, q in ipairs(SQ) do local c = ns.pos[q]; if c ~= 0 then local x, y = xy(c); if y <= 4 and x == 5 then return false end end end
  return true end }

for _, fl in ipairs(F) do
  local G = SV.explore(lvl, 3000000, fl.f)
  local res
  if not G then res = "CAP" elseif G.firstWin then res = string.format("РЕШАЕМ, ходов %d, состояний %d", G.depth[G.firstWin], G.n) else res = string.format("нерешаем (состояний %d)", G.n) end
  print(string.format("%-56s %s  %s", fl.name, fl.ctrl and "[контроль]" or "[абляция] ", res))
  SV.freeGraph(G)
end
-- авторские абляции — своими руками
print("\nавторские абляции уровня:")
for _, a in ipairs(SV.ablations(def, { cap = 3000000 })) do print(string.format("  %-30s %s", a.name, a.solvable == false and "нерешаем" or tostring(a.solvable))) end
