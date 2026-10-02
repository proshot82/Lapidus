-- build/l10a/filt10.lua — фильтры ходов (lvl, st, ns) → false запрещает переход; абляции роли и контроли кв. 10.
local R = require("core.rules")
local F = {}
local function find(lvl, tag) for q, p in ipairs(lvl.pieces) do if p.tag == tag then return q end end end
F.find = find
-- Контроль/абляция по тегу: деталь tag никогда не закрепляется в клетке (x, y).
function F.notAt(tag, x, y)
  return function(lvl, st, ns)
    if ns.dead then return true end
    local q = find(lvl, tag)
    if q and ns.fixed[q] and ns.pos[q] == R.idx(lvl, x, y) then return false end
    return true
  end
end
-- Контроль «порядок»: деталь a не закрепляется, пока деталь b свободна (снимает ловушку «a раньше b»).
function F.notBefore(a, b)
  return function(lvl, st, ns)
    if ns.dead then return true end
    local qa, qb = find(lvl, a), find(lvl, b)
    if ns.fixed[qa] and ns.pos[qa] ~= 0 and not ns.fixed[qb] and ns.pos[qb] ~= 0 then return false end
    return true
  end
end
-- Абляция «тело не держит деталь»: запрещено состояние, где незакреплённая деталь стоит на клетке тела Лапидуса.
function F.noCarry(lvl, st, ns)
  if ns.dead then return true end
  local body = {}
  for _, c in ipairs(ns.body) do body[c] = true end
  for q, p in ipairs(lvl.pieces) do
    local c = ns.pos[q]
    if p.movable and c ~= 0 and not ns.fixed[q] and body[lvl.nb[c][R.DOWN]] then return false end
  end
  return true
end
-- Абляция «деталь не кладут в дыру лесенки»: незакреплённая деталь не бывает в клетке (x, y) (дыра в полу полки).
function F.noPieceAt(x, y)
  return function(lvl, st, ns)
    if ns.dead then return true end
    local c = R.idx(lvl, x, y)
    for q, p in ipairs(lvl.pieces) do
      if p.movable and ns.pos[q] == c and not ns.fixed[q] then return false end
    end
    return true
  end
end
-- Абляция «Лапидус не входит в тоннель/колодец снизу»: ни одна клетка тела не бывает в ряду тоннеля (y = row).
function F.noBodyRow(row)
  return function(lvl, st, ns)
    if ns.dead then return true end
    for _, c in ipairs(ns.body) do local _, y = R.xy(lvl, c); if y == row then return false end end
    return true
  end
end
return F
