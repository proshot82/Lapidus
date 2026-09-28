-- visK.lua — честный видимый проигрыш для семейства K («колонна с ловушкой стояка», направление D):
--  1) ниппель (тег B) лежит незакреплённый на стене или на закреплённом — поднять его нечем
--     (поднять можно только то, что лежит на Лапидусе; карточка «Поднимает, но не носит»);
--  2) муфта (тег C) незакреплённая упала на нижний ярус (ниже ряда def.shelf) — толкать её к колонне оттуда нельзя,
--     а поднять — нечем.
return function(lvl, st)
  local def = lvl.def
  local shelf = def.shelf or 6
  local fixedAt = {}
  for k = 1, #st.pos do if st.pos[k] ~= 0 and st.fixed[k] then fixedAt[st.pos[k]] = true end end
  for q, p in ipairs(lvl.pieces) do
    if p.movable and st.pos[q] ~= 0 and not st.fixed[q] then
      local c = st.pos[q]
      local y = math.floor((c - 1) / lvl.W) + 1
      if p.tag == "B" then
        local b = lvl.nb[c][3]
        if b ~= 0 and (lvl.cell[b] == 1 or fixedAt[b]) then return true end
      elseif p.tag == "C" then
        if y > shelf then return true end
      end
    end
  end
  return false
end
