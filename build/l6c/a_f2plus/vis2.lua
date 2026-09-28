-- честный «видимый проигрыш» для раскладок с гнездом колонки над коридором (кв. 6, направление A), ред. 2:
-- ниппель лежит на полу, уступе или закреплённой детали НИЖЕ ряда гнезда — поднять его нечем
-- (поднять можно только то, что лежит на Лапидусе; карточка «Поднимает, но не носит»);
-- муфта лежит в ряду стояка, упёршись в стену с той стороны, откуда её надо толкать к стояку, или ниже ряда стояка.
-- ниппель в ряду гнезда на твёрдом, прижатый к стене с дальней от двери стороны (ред. 3).
-- (ред. 1 помечала и муфту в колодце у стены — это живые состояния, ошибка исправлена 28.09.)
return function(lvl, st)
  local sock, srcRow, srcDir
  for q, p in ipairs(lvl.pieces) do
    if p.fixture then sock = p.start end
    if p.source then
      for d = 1, 4 do if p.ports[d] then srcDir = d end end
      srcRow = math.floor((p.start - 1) / lvl.W) + 1
    end
  end
  local sockRow = math.floor((sock - 1) / lvl.W) + 2 -- ряд клетки под колонкой (порт вниз)
  for q, p in ipairs(lvl.pieces) do
    if p.tag == "nip" and st.pos[q] ~= 0 and not st.fixed[q] then
      local row = math.floor((st.pos[q] - 1) / lvl.W) + 1
      local b = lvl.nb[st.pos[q]][3]
      local onHard = (b ~= 0 and lvl.cell[b] == 1)
      for k = 1, #st.pos do if st.pos[k] == b and st.fixed[k] then onHard = true end end
      if onHard and row > sockRow then return true end
      -- ред. 3: в ряду гнезда на твёрдом, а с дальней от двери стороны стена — толкнуть к колонке неоткуда
      if onHard and row == sockRow then
        local x, sx = (st.pos[q] - 1) % lvl.W + 1, (sock + lvl.W - 1) % lvl.W + 1
        if x ~= sx then
          local away = (x < sx) and 4 or 2
          local c = lvl.nb[st.pos[q]][away]
          if c == 0 or lvl.cell[c] == 1 then return true end
        end
      end
    end
    if p.tag == "cpl" and st.pos[q] ~= 0 and not st.fixed[q] and (srcDir == 2 or srcDir == 4) then
      local row = math.floor((st.pos[q] - 1) / lvl.W) + 1
      if row > srcRow then return true end
      if row == srcRow then
        local away = (srcDir == 2) and 2 or 4 -- стояк слева (порт вправо): толкать надо, стоя справа
        local r = lvl.nb[st.pos[q]][away]
        if r == 0 or lvl.cell[r] == 1 then return true end
      end
    end
  end
  return false
end
