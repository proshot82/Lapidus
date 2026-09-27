-- общий честный «видимый проигрыш» для кандидатов кв. 6: ниппель лежит на полу, уступе или закреплённой
-- детали — поднять его уже нечем (карточка «Поднимает, но не носит» перед квартирой).
return function(lvl, st)
  for q, p in ipairs(lvl.pieces) do
    if p.tag == "nip" and st.pos[q] ~= 0 and not st.fixed[q] then
      local b = lvl.nb[st.pos[q]][3]
      if b ~= 0 and lvl.cell[b] == 1 then return true end
      for k = 1, #st.pos do if st.pos[k] == b and st.fixed[k] then return true end end
    end
  end
  return false
end
