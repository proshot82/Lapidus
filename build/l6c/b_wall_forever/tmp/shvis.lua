-- честный видимый проигрыш для «шахты» (стояк сверху над шахтой x=sx, колонка внизу той же шахты):
-- ниппель, которому надо провалиться в шахту сверху, оказался на нижнем ходу/в лунке не на колонке; муфта в лунке
-- (её надо поднимать к стояку, а со дна лунки не поднять).
return function(sx, topY, botY)
  return function(lvl, st)
    for q, p in ipairs(lvl.pieces) do
      if p.movable and st.pos[q] ~= 0 then
        local x, y = (st.pos[q] - 1) % lvl.W + 1, math.floor((st.pos[q] - 1) / lvl.W) + 1
        local b = lvl.nb[st.pos[q]][3]
        local onLap = false
        for _, c in ipairs(st.body) do if c == b then onLap = true end end
        if p.tag == "pn" and not st.fixed[q] and y > topY and not onLap then return true end
        if p.tag == "upc" and y > botY then return true end
      end
    end
    return false
  end
end
