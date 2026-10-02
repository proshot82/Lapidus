-- build/l7v_d/filters2.lua [файл уровня] — абляции через трассу хода (что случилось внутри устаканивания) и
-- ошибки «пробка не тем концом». Только решаемость, без ходов.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1] or "build/l7c/d_tee_lift/L7D.lua")
local lvl = R.compile(def)
local function find(what) for q, p in ipairs(lvl.pieces) do if p.what == what then return q end end end
local QE, QP = find("elbow"), find("plug")
local function xy(c) return R.xy(lvl, c) end
local function bodySet(st) local b = {} for _, c in ipairs(st.body) do b[c] = true end return b end
-- трасса хода st→ns: перебираем 8 ходов, находим тот, что даёт ключ ns
local function traceOf(st, ns)
  local k = R.key(ns)
  for m = 1, 8 do
    local mm = R.MOVES[m]
    local tr = {}
    local r = R.move(lvl, st, mm.which, mm.dir, tr)
    if r and R.key(r) == k then return tr end
  end
end
-- общий сдвиг тела между соседними кадрами устаканивания: все клетки уехали на один и тот же (dx,dy)
local function bodyShift(prev, st)
  if #st.body ~= #prev.body then return nil end
  local dx, dy
  for i = 1, #st.body do
    local x1, y1 = xy(prev.body[i]); local x2, y2 = xy(st.body[i])
    if dx == nil then dx, dy = x2 - x1, y2 - y1 elseif dx ~= x2 - x1 or dy ~= y2 - y1 then return nil end
  end
  return dx, dy
end
-- сдвинула ли струя Лапидуса вбок внутри устаканивания (в одном кадре сдвиг может сочетаться с падением: dx ~= 0 при любом dy)
local function lapShovedSideways(tr)
  local prev
  for _, fr in ipairs(tr) do
    local st = fr.state
    if prev and fr.kind == "settle" and not st.dead then
      local dx = bodyShift(prev, st)
      if dx and dx ~= 0 then return true end
    end
    prev = st
  end
  return false
end
-- поднял ли столб Лапидуса (тело целиком уехало вверх между кадрами settle; подъём и падение в одном кадре взаимно гасятся,
-- но такое возможно только при потере опоры сразу после подъёма — на этом поле не встречается)
local function lapLifted(tr)
  local prev
  for _, fr in ipairs(tr) do
    local st = fr.state
    if prev and fr.kind == "settle" and not st.dead then
      local dx, dy = bodyShift(prev, st)
      if dx and dy and dy < 0 then return true end
    end
    prev = st
  end
  return false
end
local function fountainCells(st)
  local col = {}
  for _, j in ipairs(R.jets(lvl, st)) do if j.dir == R.UP and not j.lapidus then for _, c in ipairs(j.cells) do col[c] = true end end end
  return col
end
local F = {}
F[#F + 1] = { name = "А6' струя вбок не сдвигает Лапидуса (ход отвергается, если внутри устаканивания тело переехало по горизонтали)", f = function(lvl, st, ns)
  local tr = traceOf(st, ns); return not (tr and lapShovedSideways(tr)) end }
F[#F + 1] = { name = "А11 столб не поднимает Лапидуса (ход отвергается, если внутри устаканивания тело переехало вверх)", f = function(lvl, st, ns)
  local tr = traceOf(st, ns); return not (tr and lapLifted(tr)) end }
for _, fl in ipairs(F) do
  local G = SV.explore(lvl, 3000000, fl.f)
  local res
  if not G then res = "CAP" elseif G.firstWin then res = string.format("РЕШАЕМ, ходов %d, состояний %d", G.depth[G.firstWin], G.n) else res = string.format("нерешаем (состояний %d)", G.n) end
  print(string.format("%-92s %s", fl.name, res))
  SV.freeGraph(G)
end
