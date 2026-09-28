-- честный «видимый проигрыш» для раскладок с гнездом колонки над коридором (кв. 6, направление A):
-- ниппель лежит на полу, уступе или закреплённой детали НИЖЕ ряда гнезда — поднять его нечем
-- (поднять можно только то, что лежит на Лапидусе; карточка «Поднимает, но не носит»);
-- муфта уткнулась в стену с той стороны, откуда её надо толкать к стояку (встать там нельзя).
return function(lvl, st)
  local sock, srcRow, srcX, srcDir
  for q, p in ipairs(lvl.pieces) do
    if p.fixture then sock = p.start end
    if p.source then
      for d = 1, 4 do if p.ports[d] then srcDir = d end end
      srcX, srcRow = (p.start - 1) % lvl.W + 1, math.floor((p.start - 1) / lvl.W) + 1
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
    end
    if p.tag == "cpl" and st.pos[q] ~= 0 and not st.fixed[q] and srcDir == 2 then
      -- стояк слева, порт вправо: муфту толкают влево, стоя справа от неё
      local r = lvl.nb[st.pos[q]][2]
      if r == 0 or lvl.cell[r] == 1 then return true end
      local row = math.floor((st.pos[q] - 1) / lvl.W) + 1
      if row ~= srcRow then
        -- муфта не в ряду стояка и лежит на твёрдом — опустить её можно, поднять нельзя
        local b = lvl.nb[st.pos[q]][3]
        if row > srcRow and b ~= 0 and lvl.cell[b] == 1 then return true end
      end
    end
  end
  return false
end
