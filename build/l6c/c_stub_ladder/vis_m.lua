-- vis_m.lua — честный «видимый проигрыш» для семейства M («два гнезда в полу», кв. 6, направление C), ред. 1.
-- Помечает только то, что видно с одного взгляда:
--  1) деталь из def.lift (ниппель) лежит, не закреплённая, на стене или закреплённом ниже нужного ряда — поднять
--     её нечем (поднять можно только то, что лежит на Лапидусе; карточка «Поднимает, но не носит»);
--  2) незакреплённая муфта (тег из def.slide) лежит на полу нижнего яруса вплотную к стене с той стороны, откуда её
--     надо толкать ко всем ещё свободным гнёздам в полу (классический тупик «ящик у стены»);
--  3) муфте некуда деться: все гнёзда в полу уже заняты.
-- Смытые детали check.lua учитывает сам.
return function(lvl, st)
  local def = lvl.def
  local lift = def.lift or {}
  local W = lvl.W
  local fixedAt = {}
  for k = 1, #st.pos do if st.pos[k] ~= 0 and st.fixed[k] then fixedAt[st.pos[k]] = k end end
  local function row(c) return math.floor((c - 1) / W) + 1 end
  local function col(c) return (c - 1) % W + 1 end
  -- гнёзда в полу: клетки прямо над стояком и отводом с портом вверх
  local sockets = {}
  for q, p in ipairs(lvl.pieces) do
    if (p.source or p.kind == "stub") and p.ports[1] then sockets[#sockets + 1] = lvl.nb[p.start][1] end
  end
  for q, p in ipairs(lvl.pieces) do
    if st.pos[q] ~= 0 and not st.fixed[q] then
      local c = st.pos[q]
      local need = p.tag and lift[p.tag]
      if need and row(c) > need then
        local b = lvl.nb[c][3]
        if b ~= 0 and (lvl.cell[b] == 1 or fixedAt[b]) then return true end
      end
      if p.tag and def.slide and def.slide[p.tag] then
        local free = {}
        for _, s in ipairs(sockets) do if not fixedAt[s] then free[#free + 1] = s end end
        if #free == 0 then return true end
        if row(c) == row(free[1]) then
          local westNeeded, eastNeeded = false, false
          for _, s in ipairs(free) do
            if col(s) < col(c) then westNeeded = true elseif col(s) > col(c) then eastNeeded = true end
          end
          local e, w = lvl.nb[c][2], lvl.nb[c][4]
          local eBlocked = (e == 0 or lvl.cell[e] == 1)
          local wBlocked = (w == 0 or lvl.cell[w] == 1)
          if westNeeded and not eastNeeded and eBlocked then return true end
          if eastNeeded and not westNeeded and wBlocked then return true end
        end
      end
    end
  end
  return false
end
