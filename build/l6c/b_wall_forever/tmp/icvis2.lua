-- честный видимый проигрыш для семейства «колонна-проход» (стояк в потолке над колонной x=sx, колонка в полу x=hx):
-- муфта на нижнем ходу или в лунке колонки (к потолку её не поднять) — видно; ниппель на дне чужой ямы / в углу — видно.
return function(sx, hx)
  return function(lvl, st)
    for q, p in ipairs(lvl.pieces) do
      if p.movable and st.pos[q] ~= 0 then
        local x, y = (st.pos[q] - 1) % lvl.W + 1, math.floor((st.pos[q] - 1) / lvl.W) + 1
        local b = lvl.nb[st.pos[q]][3]
        local onLap = false
        for _, c in ipairs(st.body) do if c == b then onLap = true end end
        if p.tag == "upc" then
          if st.fixed[q] and x == hx then return true end             -- муфта свинтилась с ниппелем в лунке колонки
          if not st.fixed[q] and y >= 5 and not onLap then return true end  -- муфта внизу: к стояку не поднять
        end
        if p.tag == "pn" and not st.fixed[q] then
          if y >= 6 then return true end
          if y == 5 and not onLap then
            local dir = (x < hx) and 4 or 2           -- откуда толкать к лунке
            local behind = lvl.nb[st.pos[q]][dir]
            if behind == 0 or lvl.cell[behind] == 1 then return true end
          end
        end
      end
    end
    return false
  end
end
