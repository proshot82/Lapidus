-- общий честный видимый проигрыш для «перевёрнутой С» (стояк в потолке x=5, колонка в полу x=hx)
return function(hx)
  return function(lvl, st)
    for q, p in ipairs(lvl.pieces) do
      if p.movable and st.pos[q] ~= 0 and not st.fixed[q] then
        local x, y = (st.pos[q] - 1) % lvl.W + 1, math.floor((st.pos[q] - 1) / lvl.W) + 1
        local b = lvl.nb[st.pos[q]][3]
        local onLap = false
        for _, c in ipairs(st.body) do if c == b then onLap = true end end
        if p.tag == "upc" and y >= 5 and not onLap then return true end       -- муфта внизу: к потолку не поднять
        if p.tag == "pn" and y >= 6 and x ~= hx then return true end          -- ниппель в чужой яме
        if p.tag == "pn" and y == 5 and not onLap then                       -- ниппель на полу: жив, если к лунке можно дотолкать
          local dir = (x < hx) and 4 or 2
          local behind = lvl.nb[st.pos[q]][dir]
          if behind == 0 or lvl.cell[behind] == 1 then return true end
        end
      end
    end
    return false
  end
end
