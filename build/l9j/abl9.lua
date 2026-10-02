-- build/l9j/abl9.lua — фильтры абляций роли для кандидатов кв. 9 (скелет «шахта»). Фильтр (lvl, st, ns): false запрещает
-- переход в ns. Возвращает таблицу фильтров.
local R = require("core.rules")
local F = {}
local function tagOf(lvl, tag) for q, p in ipairs(lvl.pieces) do if p.tag == tag then return q end end end
-- «Домкрата нет»: свободная деталь с данным тегом никогда не поднимается вверх ходом Лапидуса (толчок снизу запрещён).
function F.noLift(tag)
  return function(lvl, st, ns)
    local q = tagOf(lvl, tag)
    local c = st.pos[q]
    if c == 0 or st.fixed[q] then return true end
    if ns.pos[q] == lvl.nb[c][R.UP] then return false end
    if ns.fixed[q] and ns.pos[q] ~= c and ns.pos[q] == lvl.nb[c][R.UP] then return false end
    return true
  end
end
-- «Ловить нечем»: свободная деталь не может лежать на теле Лапидуса (ни на какой его клетке).
function F.noCatch(tag)
  return function(lvl, st, ns)
    local q = tagOf(lvl, tag)
    local c = ns.pos[q]
    if c == 0 or ns.fixed[q] then return true end
    local below = lvl.nb[c][R.DOWN]
    for _, b in ipairs(ns.body) do if b == below then return false end end
    return true
  end
end
return F
