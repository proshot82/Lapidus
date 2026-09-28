-- visQ.lua — честный видимый проигрыш для семейства Q («разворот над карманом»):
--  1) ниппель (B) лежит незакреплённый на стене или на закреплённом — поднять его нечем;
--  2) муфта (C) в нижнем коридоре прижата к стене с той стороны, откуда её надо толкать к гнезду,
--     или вытолкнута туда, откуда ей до гнезда не дойти (упала выше ряда нижнего коридора не бывает).
return function(lvl, st)
  local W = lvl.W
  local fixedAt = {}
  for k = 1, #st.pos do if st.pos[k] ~= 0 and st.fixed[k] then fixedAt[st.pos[k]] = true end end
  local sockX, sockY
  for q, p in ipairs(lvl.pieces) do if p.source then sockX = (p.start - 1) % W + 2; sockY = math.floor((p.start - 1) / W) + 1 end end
  for q, p in ipairs(lvl.pieces) do
    if p.movable and st.pos[q] ~= 0 and not st.fixed[q] then
      local c = st.pos[q]
      local x, y = (c - 1) % W + 1, math.floor((c - 1) / W) + 1
      local b = lvl.nb[c][3]
      local onSolid = b ~= 0 and (lvl.cell[b] == 1 or fixedAt[b])
      if p.tag == "B" and onSolid then return true end
      if p.tag == "C" then
        if y ~= sockY then return true end
        if onSolid then
          local back = lvl.nb[c][(x > sockX) and 2 or 4]
          if back == 0 or lvl.cell[back] == 1 or fixedAt[back] then return true end
        end
      end
    end
  end
  return false
end
