-- visR.lua — честный видимый проигрыш для семейства R (муфта на верхнем уступе, сталкивается в шахту над карманом):
--  1) ниппель (B) незакреплённый лежит на стене или на закреплённом;
--  2) муфта (C) незакреплённая лежит на стене/закреплённом НИЖЕ уступа (def.shelf) — поднять её нечем,
--     или на уступе прижата к стене с той стороны, откуда её надо толкать к шахте (def.dropx).
return function(lvl, st)
  local def = lvl.def
  local W = lvl.W
  local fixedAt = {}
  for k = 1, #st.pos do if st.pos[k] ~= 0 and st.fixed[k] then fixedAt[st.pos[k]] = true end end
  for q, p in ipairs(lvl.pieces) do
    if p.movable and st.pos[q] ~= 0 and not st.fixed[q] then
      local c = st.pos[q]
      local x, y = (c - 1) % W + 1, math.floor((c - 1) / W) + 1
      local b = lvl.nb[c][3]
      local onSolid = b ~= 0 and (lvl.cell[b] == 1 or fixedAt[b])
      if p.tag == "B" and onSolid then return true end
      if p.tag == "C" and onSolid then
        if y > def.shelf then return true end
        if y == def.shelf and x ~= def.dropx then
          local back = lvl.nb[c][(x > def.dropx) and 2 or 4]
          if back == 0 or lvl.cell[back] == 1 or fixedAt[back] then return true end
        end
      end
    end
  end
  return false
end
