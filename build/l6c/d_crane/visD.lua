-- visD.lua — честный видимый проигрыш для семейства D2 («две двери в потолке»):
--  1) муфта (тег C, её надо ПОДНЯТЬ в гнездо стояка) лежит незакреплённая на стене или на закреплённом;
--  2) ниппель (тег B, его ВДВИГАЮТ в гнездо колонки по верхнему ходу) упал ниже ряда def.shelf,
--     или в ряду def.shelf прижат к стене с той стороны, откуда его надо толкать к свободному гнезду колонки.
return function(lvl, st)
  local def = lvl.def
  local shelf = def.shelf or 3
  local W = lvl.W
  local fixedAt = {}
  for k = 1, #st.pos do if st.pos[k] ~= 0 and st.fixed[k] then fixedAt[st.pos[k]] = true end end
  local sockX
  for q, p in ipairs(lvl.pieces) do if p.fixture then sockX = (p.start - 1) % W + 1 end end
  for q, p in ipairs(lvl.pieces) do
    if p.movable and st.pos[q] ~= 0 and not st.fixed[q] then
      local c = st.pos[q]
      local x, y = (c - 1) % W + 1, math.floor((c - 1) / W) + 1
      local b = lvl.nb[c][3]
      local onSolid = b ~= 0 and (lvl.cell[b] == 1 or fixedAt[b])
      if p.tag == "C" and onSolid then return true end
      if p.tag == "B" then
        if y > shelf then return true end
        if y == shelf and onSolid then
          local dir = (x > sockX) and 2 or 4 -- толкать надо со стороны, противоположной гнезду
          local back = lvl.nb[c][dir]
          if back == 0 or lvl.cell[back] == 1 or fixedAt[back] then return true end
        end
      end
    end
  end
  return false
end
