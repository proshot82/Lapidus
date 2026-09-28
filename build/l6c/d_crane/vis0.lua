-- vis0.lua — черновой видимый проигрыш (для прототипов): незакреплённая деталь лежит на стене или на закреплённом
-- (поднять можно только то, что лежит на Лапидусе).
return function(lvl, st)
  local fixedAt = {}
  for k = 1, #st.pos do if st.pos[k] ~= 0 and st.fixed[k] then fixedAt[st.pos[k]] = true end end
  for q, p in ipairs(lvl.pieces) do
    if p.movable and st.pos[q] ~= 0 and not st.fixed[q] then
      local b = lvl.nb[st.pos[q]][3]
      if b ~= 0 and (lvl.cell[b] == 1 or fixedAt[b]) then return true end
    end
  end
  return false
end
