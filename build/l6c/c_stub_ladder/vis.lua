-- vis.lua — честный «видимый проигрыш» для кандидатов направления C (ред. 1).
-- Деталь с тегом из def.lift (tag → ряд, куда её надо поднять) лежит, не будучи закреплённой, на стене или на
-- закреплённом ниже нужного ряда — поднять её нечем (поднять можно только то, что лежит на Лапидусе;
-- карточка «Поднимает, но не носит»). Смытые детали учитывает check.lua сам.
return function(lvl, st)
  local lift = lvl.def.lift or {}
  local fixedAt = {}
  for k = 1, #st.pos do if st.pos[k] ~= 0 and st.fixed[k] then fixedAt[st.pos[k]] = true end end
  for q, p in ipairs(lvl.pieces) do
    local need = p.tag and lift[p.tag]
    if need and st.pos[q] ~= 0 and not st.fixed[q] then
      local row = math.floor((st.pos[q] - 1) / lvl.W) + 1
      if row > need then
        local b = lvl.nb[st.pos[q]][3]
        if b ~= 0 and (lvl.cell[b] == 1 or fixedAt[b]) then return true end
      end
    end
  end
  return false
end
