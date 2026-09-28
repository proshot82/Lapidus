-- честный видимый проигрыш семейства «ниппель-стена» (ниппель падает сквозь дыру D на колонку в перекрёстке P
-- нижнего хода и становится стеной; муфта едет по верхнему ходу y=uy к стояку, стоящему справа):
-- • муфта ниже верхнего хода и не лежит на Лапидусе — её не поднять;
-- • муфта закреплена не у стояка (например, села на ниппель в яме);
-- • муфта на верхнем ходу прижата слева к стене (толкать к стояку не откуда);
-- • ниппель лёг в нижнем ходу и прижат к стене с той стороны, откуда его надо толкать к P.
return function(px, py, uy)
  return function(lvl, st)
    local function wallAt(c) return c == 0 or lvl.cell[c] == 1 end
    local onLap = {}
    for _, b in ipairs(st.body) do onLap[b] = true end
    for q, p in ipairs(lvl.pieces) do
      local c = st.pos[q]
      if p.movable and c ~= 0 then
        local x, y = (c - 1) % lvl.W + 1, math.floor((c - 1) / lvl.W) + 1
        local below = lvl.nb[c][3]
        if p.tag == "cpl" then
          if st.fixed[q] then
            local src = false
            for d = 1, 4 do local t = lvl.nb[c][d]; for k, pp in ipairs(lvl.pieces) do if pp.source and st.pos[k] == t then src = true end end end
            if not src then return true end
          else
            if y > uy and not onLap[below] then return true end
            if y == uy and wallAt(lvl.nb[c][4]) then return true end
          end
        elseif p.tag == "nip" and not st.fixed[q] then
          if y == py and not onLap[below] and x ~= px then
            local from = lvl.nb[c][(x < px) and 4 or 2]
            if wallAt(from) then return true end
          end
        end
      end
    end
    return false
  end
end
