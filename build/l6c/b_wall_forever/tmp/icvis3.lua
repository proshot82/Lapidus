-- честный видимый проигрыш «колонна-проход» (стояк в потолке над (sx, sy+1), лунка колонки под нижним ходом в x=hx):
-- • муфта внизу (на нижнем ходу не на Лапидусе, в лунке) — к потолку её не поднять;
-- • деталь прижата к стене с той стороны, откуда её надо толкать к цели (как ящик в углу);
-- • ниппель в чужой яме или лёг в лунку не свинтившись.
return function(sx, sy, hx, lowY)
  return function(lvl, st)
    local function wallAt(c) return c == 0 or lvl.cell[c] == 1 end
    for q, p in ipairs(lvl.pieces) do
      if p.movable and st.pos[q] ~= 0 and not (st.fixed[q] and ((p.tag == "upc" and st.pos[q] == (sy) * lvl.W + sx) or p.tag == "pn")) then
        local c = st.pos[q]
        local x, y = (c - 1) % lvl.W + 1, math.floor((c - 1) / lvl.W) + 1
        local b = lvl.nb[c][3]
        local onLap = false
        for _, bc in ipairs(st.body) do if bc == b then onLap = true end end
        if p.tag == "upc" then
          if st.fixed[q] then return true end                         -- муфта прикрутилась не к стояку
          if y >= lowY and not onLap then return true end            -- внизу: не поднять
          if y < lowY and x ~= sx then                               -- наверху: толкать к гнезду стояка
            local from = lvl.nb[c][(x < sx) and 4 or 2]
            if wallAt(from) then return true end
          end
        elseif p.tag == "pn" and not st.fixed[q] then
          if y > lowY then return true end                           -- в яме, не свинтился
          if y == lowY and not onLap and x ~= hx then
            local from = lvl.nb[c][(x < hx) and 4 or 2]
            if wallAt(from) then return true end
          end
          if y < lowY and x ~= sx and not onLap then
            local from = lvl.nb[c][(x < sx) and 4 or 2]
            local below = lvl.nb[c][3]
            -- к гнезду его не дотолкать и вниз ему некуда
            if wallAt(from) and wallAt(below) then return true end
          end
        end
      end
    end
    return false
  end
end
