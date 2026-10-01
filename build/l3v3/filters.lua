-- build/l3v3/filters.lua [файл] — абляции роли и контроли (фильтры ходов). Контроль обязан остаться решаемым.
local L = dofile("build/l3v3/lib.lua")
local R = L.R
local path = arg[1] or "levels/03.lua"
local def = dofile(path)
local lvl = R.compile(def)
local SQ = {}
for q, p in ipairs(lvl.pieces) do if p.porcelain then SQ[#SQ + 1] = q end end
local function xy(c) return R.xy(lvl, c) end
local function bodySet(st) local b = {} for _, c in ipairs(st.body) do b[c] = true end return b end
local function isHeadMove(st, ns)
  -- ход головой: голова ушла в новую клетку (растяжение/скольжение) либо сжатие при неподвижных ногах
  local old = bodySet(st)
  local newHead = ns.body[#ns.body]
  if not old[newHead] then return true end
  if #ns.body < #st.body and ns.body[1] == st.body[1] then return true end
  return false
end
local PIT = {}
for c = 1, lvl.N do if lvl.cell[c] == 2 then PIT[c] = true end end
local F = {}
local function add(name, ctrl, f) F[#F + 1] = { name = name, ctrl = ctrl, f = f } end
-- контроли
add("К1 голова не ходит вовсе (все ходы ногами)", true, function(lvl, st, ns) return not isHeadMove(st, ns) end)
add("К2 подставку нельзя смыть, пока на ней НЕТ мыла (запрет ошибки подсказки №1)", true, function(lvl, st, ns)
  for _, q in ipairs(SQ) do
    if st.pos[q] ~= 0 and ns.pos[q] == 0 then
      local up = lvl.nb[st.pos[q]][1]
      local topped = false
      for _, r in ipairs(SQ) do if st.pos[r] == up then topped = true end end
      if not topped then return false end
    end
  end
  return true end)
add("К3 мыло не толкать влево", true, function(lvl, st, ns)
  for _, q in ipairs(SQ) do if st.pos[q] ~= 0 and ns.pos[q] ~= 0 and ns.pos[q] == lvl.nb[st.pos[q]][4] then return false end end
  return true end)
add("К4 мыло не бывает в (3,4)", true, function(lvl, st, ns)
  for _, q in ipairs(SQ) do if ns.pos[q] ~= 0 then local x, y = xy(ns.pos[q]); if x == 3 and y == 4 then return false end end end
  return true end)
add("К5 лифт только на одну клетку (мыло не выше ряда 5 в колонке x=5)", true, function(lvl, st, ns)
  for _, q in ipairs(SQ) do if ns.pos[q] ~= 0 then local x, y = xy(ns.pos[q]); if x == 5 and y <= 4 then return false end end end
  return true end)
add("К6 Лапидус не возвращается в нишу (2,6) после ухода", true, function(lvl, st, ns)
  local niche = (6 - 1) * lvl.W + 2
  local was = false
  for _, c in ipairs(st.body) do if c == niche then was = true end end
  if was then return true end
  for _, c in ipairs(ns.body) do if c == niche then return false end end
  return true end)
add("К7 мыло на голове только над сливом (мост разрешён, иная «голова под мылом» — нет)", true, function(lvl, st, ns)
  local head = ns.body[#ns.body]
  local up = lvl.nb[head][1]
  for _, q in ipairs(SQ) do if ns.pos[q] == up and not PIT[lvl.nb[head][3]] then return false end end
  return true end)
-- дополнительные абляции
add("А1 ноги не ходят вовсе (всё головой)", false, function(lvl, st, ns) return isHeadMove(st, ns) end)
add("А2 мыло не лежит на середине тела (только на концах)", false, function(lvl, st, ns)
  local b = bodySet(ns); local head, heel = ns.body[#ns.body], ns.body[1]
  for _, q in ipairs(SQ) do local c = ns.pos[q]; if c ~= 0 then local d = lvl.nb[c][3]; if b[d] and d ~= head and d ~= heel then return false end end end
  return true end)
add("А3 мыло не лежит на ногах (на клетке ног)", false, function(lvl, st, ns)
  local heel = ns.body[1]
  for _, q in ipairs(SQ) do if ns.pos[q] ~= 0 and lvl.nb[ns.pos[q]][3] == heel then return false end end
  return true end)
add("А4 мыло не падает на Лапидуса (не оказывается на теле иначе, чем толчком)", false, function(lvl, st, ns)
  -- запрещено: мыло после хода лежит на теле, а до хода на этой клетке не лежало и не было толкнуто (сдвиг по вертикали)
  local b = bodySet(ns)
  for _, q in ipairs(SQ) do
    local c0, c1 = st.pos[q], ns.pos[q]
    if c1 ~= 0 and b[lvl.nb[c1][3]] and c0 ~= c1 then
      local x0, y0 = xy(c0); local x1, y1 = xy(c1)
      if x0 == x1 and y1 > y0 then return false end
    end
  end
  return true end)
add("А5 без сжатий", false, function(lvl, st, ns) return #ns.body >= #st.body end)
add("А6 без скольжений (длина < Lmax всегда)", false, function(lvl, st, ns) return #ns.body < lvl.Lmax end)
add("А7 мыло не проходит через (5,4)", false, function(lvl, st, ns)
  for _, q in ipairs(SQ) do if ns.pos[q] ~= 0 then local x, y = xy(ns.pos[q]); if x == 5 and y == 4 then return false end end end
  return true end)
add("А8 мыло не ложится на мыло И мыло не падает на Лапидуса", false, function(lvl, st, ns)
  return F[10].f(lvl, st, ns) and (function()
    for _, q in ipairs(SQ) do local c = ns.pos[q]; if c ~= 0 then local up = lvl.nb[c][1]; for _, r in ipairs(SQ) do if ns.pos[r] == up then return false end end end end
    return true end)() end)
add("А9 Лапидус не бывает в (6,7) (клетка над сливом)", false, function(lvl, st, ns)
  for _, c in ipairs(ns.body) do local x, y = xy(c); if x == 6 and y == 7 then return false end end
  return true end)
for _, fl in ipairs(F) do
  local r = L.metrics(def, fl.f)
  print(string.format("%-78s %s  %s", fl.name, fl.ctrl and "[контроль]" or "[абляция] ", L.fmt(r)))
  io.stdout:flush()
end
print("\nавторские абляции уровня:")
for _, a in ipairs(L.SV.ablations(def, { cap = 3000000 })) do print(string.format("  %-28s %s", a.name, a.solvable == false and "нерешаем" or tostring(a.solvable))) end
