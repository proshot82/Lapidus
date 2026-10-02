-- build/l9a/filt.lua — узкие фильтры ходов (абляции роли и контроли) для кандидатов кв. 9 «Гребёнка».
-- Фильтр получает (lvl, st, ns) и возвращает false, если переход запрещён (solver/solve.lua, M.explore).
local R = require("core.rules")
local F = {}
local function find(lvl, tag) for q, p in ipairs(lvl.pieces) do if p.tag == tag then return q end end end
F.find = find
-- клетки столбов (струи вверх не от Лапидуса) и клетка над верхушкой каждого столба
local function columns(lvl, ns)
  local col, top = {}, {}
  for _, j in ipairs(R.jets(lvl, ns)) do
    if j.dir == R.UP and not j.lapidus and #j.cells > 0 then
      for _, c in ipairs(j.cells) do col[c] = true end
      local t = lvl.nb[j.cells[#j.cells]][R.UP]; if t ~= 0 then top[t] = true end
    end
  end
  return col, top
end
F.columns = columns
-- мокрая ли сеть гребёнки (хоть одна pipe мокрая) в состоянии ns
function F.wet(lvl, ns)
  if ns.dead then return false end
  local w = R.water(lvl, ns)
  for q, p in ipairs(lvl.pieces) do if p.kind == "pipe" and w.wet[q] then return true end end
  return false
end
-- Абляция «фонтан не держит деталь на весу»: незакреплённая деталь не бывает в столбе и на гребне (над верхушкой).
function F.noHover(lvl, st, ns)
  if ns.dead then return true end
  local col, top = columns(lvl, ns)
  for q, p in ipairs(lvl.pieces) do
    local c = ns.pos[q]
    if p.movable and c ~= 0 and not ns.fixed[q] and (col[c] or top[c]) then return false end
  end
  return true
end
-- Абляция «деталь в столбе не вдавить сверху»: незакреплённая деталь в столбе/на гребне, а прямо над ней — тело Лапидуса.
function F.noPushDown(lvl, st, ns)
  if ns.dead then return true end
  local col, top = columns(lvl, ns)
  local body = {}
  for _, c in ipairs(ns.body) do body[c] = true end
  for q, p in ipairs(lvl.pieces) do
    local c = ns.pos[q]
    if p.movable and c ~= 0 and not ns.fixed[q] and (col[c] or top[c]) and body[lvl.nb[c][R.UP]] then return false end
  end
  return true
end
-- Абляция «деталь не едет по гребням»: незакреплённая деталь не бывает на гребне (клетке над верхушкой столба)
-- — то есть струя может лишь держать деталь в столбе, но не переносить через выход.
function F.noRide(lvl, st, ns)
  if ns.dead then return true end
  local _, top = columns(lvl, ns)
  for q, p in ipairs(lvl.pieces) do
    local c = ns.pos[q]
    if p.movable and c ~= 0 and not ns.fixed[q] and top[c] then return false end
  end
  return true
end
-- Контроль «деталь не трогают, пока гребёнка сухая»: пока сеть гребёнки сухая, ни одна деталь, кроме ниппеля,
-- не сдвигается с места (решаем — порядок «сначала вода» и есть решение).
function F.dryHandsOff(lvl, st, ns)
  if ns.dead then return true end
  if F.wet(lvl, st) then return true end
  for q, p in ipairs(lvl.pieces) do
    if p.movable and p.tag ~= "nip" and ns.pos[q] ~= st.pos[q] then return false end
  end
  return true
end
-- Контроль «деталь не прикручивается к гребёнке всухую»: запрещён переход, в котором деталь стала закреплённой,
-- пока гребёнка сухая (кроме ниппеля).
function F.noDryScrew(lvl, st, ns)
  if ns.dead then return true end
  if F.wet(lvl, st) then return true end
  for q, p in ipairs(lvl.pieces) do
    if p.movable and p.tag ~= "nip" and ns.fixed[q] and not st.fixed[q] then return false end
  end
  return true
end
-- Контроль/абляция по тегу: деталь tag никогда не закрепляется в клетке cell (x, y).
function F.notAt(tag, x, y)
  return function(lvl, st, ns)
    if ns.dead then return true end
    local q = find(lvl, tag)
    if q and ns.fixed[q] and ns.pos[q] == R.idx(lvl, x, y) then return false end
    return true
  end
end
return F
