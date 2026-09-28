-- vis.lua — видимый проигрыш для семейства «стопка в лифте» (кв. 7, направление B).
-- local V = dofile("build/l7c/b_lift_cargo/vis.lua"); def.visibleLoss = V.make("mine" | "wide")
-- Решений не содержит. Правила (одной фразой каждое):
--  mine:
--   A. деталь лежит на полу там, откуда её не втолкнуть ни в одну клетку струи: путь к столбу по её ряду
--      упирается в стену или закреплённое, либо за ней нет места, откуда толкать (поднять с пола нечем);
--   B. фонтана больше нет (вверх из столба ничего не бьёт, Лапидус не в счёт), а тройник ещё не у раковины;
--   C. заглушка и тройник обе в столбе, и заглушка ниже тройника (из стопки её не вынуть);
--      то же для переходника: переходник и тройник оба в столбе, и переходник выше тройника.
--  wide (скептик, «при сомнении — шире»), сверх mine:
--   D. тройник закреплён не у раковины (ушёл в надставку и т. п.);
--   E. тройник закреплён у раковины, а заглушки на нём нет и она не над ним в столбе;
--   F. Лапидус целиком в шахте выше последнего ряда, где из столба есть боковой выход, и не прикручен
--      (вниз его не пустит фонтан);
--   G. ниппель поднят фонтаном (свободен и стоит в столбе выше основания) — вниз он уже не вернётся.
local R = require("core.rules")
local M = {}

function M.make(mode)
  local wide = (mode == "wide")
  return function(lvl, st)
    local W = lvl.W
    local P = lvl.pieces
    local src, fix, tq, pq, nq, aq
    for q, p in ipairs(P) do
      if p.source then src = q elseif p.fixture then fix = q end
      if p.tag == "tee" then tq = q elseif p.tag == "plug" then pq = q elseif p.tag == "nip" then nq = q elseif p.tag == "adp" then aq = q end
    end
    local sx, sy = R.xy(lvl, P[src].start)
    local fixedAt, pieceAt = {}, {}
    for q = 1, #st.pos do
      local c = st.pos[q]
      if c ~= 0 then pieceAt[c] = q; if st.fixed[q] then fixedAt[c] = true end end
    end
    local function wall(c) return c == 0 or lvl.cell[c] == R.WALL end
    local function solid(c) return wall(c) or fixedAt[c] end
    local function inCol(c) local x = R.xy(lvl, c); return x == sx end
    -- струя вверх из столба без учёта Лапидуса
    local w = R.water(lvl, st, nil, true)
    local jetUp = false
    for _, L in ipairs(w.leaks) do
      local x = R.xy(lvl, L.cell)
      if L.dir == R.UP and x == sx then jetUp = true end
    end
    -- нижняя клетка струи (первая над верхним закреплённым в столбе)
    local base = P[src].start
    while true do
      local u = lvl.nb[base][R.UP]
      if u ~= 0 and fixedAt[u] then base = u else break end
    end
    local firstJet = lvl.nb[base][R.UP]
    -- A: деталь на полу, которую не втолкнуть в столб по её ряду
    local function canEnter(c)
      local x, y = R.xy(lvl, c)
      if x == sx then return true end
      local d = (x < sx) and R.RIGHT or R.LEFT
      local back = lvl.nb[c][R.OPP[d]]
      if solid(back) or lvl.cell[back] == R.PIT then return false end
      local t = c
      while true do
        t = lvl.nb[t][d]
        if t == 0 or solid(t) then return false end
        local tx = R.xy(lvl, t)
        if tx == sx then
          -- клетка столба должна быть клеткой струи (не ниже основания)
          local _, ty = R.xy(lvl, t)
          local _, fy = R.xy(lvl, firstJet)
          return ty <= fy
        end
      end
    end
    for q, p in ipairs(P) do
      local c = st.pos[q]
      if p.movable and c ~= 0 and not st.fixed[q] and not inCol(c) then
        local b = lvl.nb[c][R.DOWN]
        local onFloor = solid(b)
        if onFloor and not canEnter(c) then return true end
      end
    end
    -- B: фонтана нет, а тройник не у раковины
    local tAtFix = false
    if tq and st.fixed[tq] and st.pos[tq] ~= 0 then
      for d = 1, 4 do if lvl.nb[st.pos[tq]][d] == st.pos[fix] then tAtFix = true end end
    end
    if not jetUp and not tAtFix then return true end
    -- C: заглушка ниже тройника в столбе
    if pq and tq and st.pos[pq] ~= 0 and st.pos[tq] ~= 0 and inCol(st.pos[pq]) and inCol(st.pos[tq]) then
      if st.pos[pq] > st.pos[tq] then return true end
    end
    if aq and tq and st.pos[aq] ~= 0 and st.pos[tq] ~= 0 and inCol(st.pos[aq]) and inCol(st.pos[tq]) then
      if st.pos[aq] < st.pos[tq] then return true end
    end
    if wide then
      if tq and st.fixed[tq] and not tAtFix then return true end                     -- D
      if tAtFix then                                                                    -- E
        local above = lvl.nb[st.pos[tq]][R.UP]
        local pc = st.pos[pq]
        if not (pc ~= 0 and (pc == above or (inCol(pc) and pc < st.pos[tq]))) then return true end
      end
      -- F: Лапидус целиком в шахте выше последнего ряда с боковым выходом и не прикручен
      local piece = R.occupancy(st)
      local anch = R.endScrew(lvl, st, piece, "head") or R.endScrew(lvl, st, piece, "heel")
      if not anch then
        local allCol, maxRow = true, 0
        for _, c in ipairs(st.body) do
          local x, y = R.xy(lvl, c)
          if x ~= sx then allCol = false end
          if y > maxRow then maxRow = y end
        end
        -- самый верхний ряд с выходом, который ниже его нижней клетки → не выйти
        local topExit = 1e9
        for y = 1, lvl.H do
          local c = R.idx(lvl, sx, y)
          if lvl.cell[c] ~= R.WALL and y < sy then
            local l, r = lvl.nb[c][R.LEFT], lvl.nb[c][R.RIGHT]
            if (l ~= 0 and lvl.cell[l] ~= R.WALL and not fixedAt[l] and pieceAt[l] == nil) or (r ~= 0 and lvl.cell[r] ~= R.WALL and not fixedAt[r] and pieceAt[r] == nil) then
              if y < topExit then topExit = y end
            end
          end
        end
        if allCol and maxRow < topExit and jetUp then return true end
      end
      -- G: ниппель поднят фонтаном
      if nq and st.pos[nq] ~= 0 and not st.fixed[nq] and inCol(st.pos[nq]) then
        local _, ny = R.xy(lvl, st.pos[nq])
        local _, fy = R.xy(lvl, firstJet)
        if ny < fy then return true end
      end
    end
    return false
  end
end

return M
