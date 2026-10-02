-- build/l4v3/controls.lua файл — контроли автора (из файла уровня) и свои: решаем ли, ходы, скрытые, обезьяна, двери. Без ходов.
package.path = "./?.lua;" .. package.path
local L = dofile("build/l4v3/lib.lua")
local SV = require("solver.solve")
local file = arg[1]
local def = dofile(file)
local function report(name, d, filter)
  local A = L.load(d, { filter = filter })
  if A.unsolvable then print(string.format("  %-58s НЕРЕШАЕМ (сост %s)", name, tostring(A.n))) return end
  local cls = L.classes(A)
  local M = L.mark(A, cls, {})
  local m = A.V.measure(A.G, A.good, M)
  local H = L.hiddenOf(A, M)
  local sp, cl = {}, {}
  for _, dd in ipairs(L.doors(A, H, false)) do sp[dd.step] = true; cl[cls[L.classOf(A, cls, A.sts[dd.to])][1]] = true end
  local spl, cll = {}, {}
  for s = 0, A.opt do if sp[s] then spl[#spl + 1] = s end end
  for k in pairs(cl) do cll[#cll + 1] = k end
  print(string.format("  %-58s ходов %2d | сост %5d | скрытых %.1f %% | обезьяна %.3f %% | глубина %d | двери с кратчайших [%s] %s",
    name, A.opt, A.G.n, m.hiddenPct, m.smart, m.maxDeep, table.concat(spl, ","), table.concat(cll, "+")))
  L.free(A)
end
print(file)
report("исходный", def)
for _, c in ipairs(def.controls or {}) do
  local d = SV.deepcopy(def)
  if c.mutate then c.mutate(d) end
  report("автор: " .. c.name, d, c.filter)
end
-- свои контроли
local function lowElbForbidden(lvl, st, ns)
  local e; for q, p in ipairs(lvl.pieces) do if p.tag == "elb" then e = q end end
  if ns.pos[e] ~= 0 and not ns.fixed[e] then local _, y = require("core.rules").xy(lvl, ns.pos[e]); if y >= 5 then return false end end
  return true
end
report("свой: угольник нельзя уронить вниз мимо машинки", def, lowElbForbidden)
local function noCatch(lvl, st, ns)
  local n, w; for q, p in ipairs(lvl.pieces) do if p.tag == "nip" then n = q end; if p.fixture then w = lvl.nb[p.start][1] end end
  return not (ns.fixed[n] and ns.pos[n] == w)
end
report("свой: ниппель не ловится машинкой (сито выключено для ниппеля)", def, noCatch)
report("свой: без обеих ловушек маршрута", def, function(l, s, n) return lowElbForbidden(l, s, n) and noCatch(l, s, n) end)
local function noEP(lvl, st, ns)
  local e, pipe; for q, p in ipairs(lvl.pieces) do if p.tag == "elb" then e = q end; if p.kind == "pipe" then pipe = lvl.nb[p.start][2] end end
  return not (ns.fixed[e] and ns.pos[e] == pipe)
end
report("свой: угольник не прикручивается к выходу трубы", def, noEP)
-- порядок в шахте: ниппель не может закрыть вход раньше муфты (ошибка порядка запрещена)
local function noOrder(lvl, st, ns)
  local S; for q, p in ipairs(lvl.pieces) do if p.source then S = p.start end end
  local B = lvl.nb[S][1]; local T = lvl.nb[B][1]
  local atB, atT = false, false
  for q, p in ipairs(lvl.pieces) do if p.movable and ns.fixed[q] then if ns.pos[q] == B then atB = true end; if ns.pos[q] == T then atT = true end end end
  return not (atT and not atB)
end
report("свой: ошибка порядка в шахте запрещена", def, noOrder)
