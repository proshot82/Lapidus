-- «шахта со стопкой»: деталь лежит в лунке колонки не свинченной (на колонке или на другой детали) —
-- поднять её оттуда нечем, и она закрывает колонку: видно сразу.
return function(px, py)
  return function(lvl, st)
    for q, p in ipairs(lvl.pieces) do
      if p.movable and st.pos[q] ~= 0 and not st.fixed[q] then
        local x, y = (st.pos[q] - 1) % lvl.W + 1, math.floor((st.pos[q] - 1) / lvl.W) + 1
        if x == px and y >= py then
          local b = lvl.nb[st.pos[q]][3]
          local onLap = false
          for _, c in ipairs(st.body) do if c == b then onLap = true end end
          if not onLap then return true end
        end
      end
    end
    return false
  end
end
