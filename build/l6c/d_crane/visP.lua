-- visP.lua — честный видимый проигрыш для семейств P/P7/KP (ред. 2):
--  1) ниппель (B) или муфта (C) лежат незакреплённые на стене или на закреплённом — поднять их нечем
--     (поднять можно только то, что лежит на Лапидусе; карточка «Поднимает, но не носит»);
--  2) ниппель закреплён не в гнезде колонки (например, упал в карман на муфту) — колонке его уже не отдать.
return function(lvl, st)
  local fixedAt = {}
  for k = 1, #st.pos do if st.pos[k] ~= 0 and st.fixed[k] then fixedAt[st.pos[k]] = true end end
  local sock
  for q, p in ipairs(lvl.pieces) do
    if p.fixture then for d = 1, 4 do if p.ports[d] then sock = lvl.nb[p.start][d] end end end
  end
  for q, p in ipairs(lvl.pieces) do
    if p.movable and st.pos[q] ~= 0 then
      if not st.fixed[q] then
        local b = lvl.nb[st.pos[q]][3]
        if b ~= 0 and (lvl.cell[b] == 1 or fixedAt[b]) then return true end
      elseif p.tag == "B" and st.pos[q] ~= sock then
        return true
      end
    end
  end
  return false
end
