-- verify_vis.lua — более широкий, но честный visibleLoss для a1 (проверка скептика, 28.09).
-- Режимы (MODE): "A" — ниппель в вертикальной шахте, из которой в ряд гнезда его можно лишь поднять, а толкнуть к двери
-- неоткуда (с дальней от двери стороны в ряду гнезда стена) — то же правило, что ред. 3 у автора, но без «на твёрдом»;
-- "B" — дверь закрыта (ниппель вкручен), а муфта ещё наверху по дальнюю от стояка сторону двери: вниз ей только в угол;
-- "AB" — оба. Всё поверх vis2.lua автора.
local base = dofile("build/l6c/a_f2plus/vis2.lua")
return function(mode)
  return function(lvl, st)
    if base(lvl, st) then return true end
    local sock, nipq, cplq
    for q, p in ipairs(lvl.pieces) do
      if p.fixture then sock = lvl.nb[p.start][3] end
      if p.tag == "nip" then nipq = q elseif p.tag == "cpl" then cplq = q end
    end
    local W = lvl.W
    local function xy(c) return (c - 1) % W + 1, math.floor((c - 1) / W) + 1 end
    local function wall(c) return c == 0 or lvl.cell[c] == 1 end
    local sx, sy = xy(sock)
    local np = st.pos[nipq]
    if mode:find("A") and np ~= 0 and not st.fixed[nipq] then
      local x, y = xy(np)
      if x ~= sx then
        -- идём по столбцу к ряду гнезда: все клетки по пути (кроме самой клетки ряда гнезда) зажаты стенами с боков
        local ok, c = true, np
        local dir = (y > sy) and 1 or 3
        for _ = 1, math.abs(y - sy) do
          if not (wall(lvl.nb[c][2]) and wall(lvl.nb[c][4])) then ok = false break end
          c = lvl.nb[c][dir]
          if c == 0 or lvl.cell[c] == 1 then ok = false break end
        end
        if ok then
          local away = (x < sx) and 4 or 2
          if wall(lvl.nb[c][away]) then return true end
        end
      end
    end
    if mode:find("B") and st.fixed[nipq] and st.pos[cplq] ~= 0 and not st.fixed[cplq] then
      local x, y = xy(st.pos[cplq])
      if y <= sy and x > sx then return true end
    end
    return false
  end
end
