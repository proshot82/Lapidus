-- fvis.lua — видимый проигрыш для семейства «паром» (заглушка, тройник, ниппель; лифт — столб фонтана),
-- по образцу самой широкой честной разметки скептика кв. 7 (build/l7c/b_lift_cargo/verify2_vis.lua: статичные
-- правила + правило N «проигрыш вскрывается следующим толчком»). Для экспериментов:
--   local V = dofile("build/l7c/c_p2b_plus/fvis.lua"); def.visibleLoss = V.make(def)
-- Правила (одной фразой каждое):
--  A  свободная деталь (или свинченная пара) больше не попадёт в столб так, чтобы поехать: её можно только толкать
--     вдоль ряда (с падением с уступов), а путь к столбу упирается в стену/закреплённое, или толкать не из чего
--     (клетка для толкающего конца — там, куда Лапидусу не пройти в обход самой детали; подвижные детали на пути
--     не в счёт);
--  N  то же, когда единственный оставшийся вход — первая клетка струи над закреплённым основанием, куда низ детали
--     прикрутится (правило N скептика, обобщённое на уровни, где в столб можно войти и выше основания);
--  B  фонтана вверх нет, а тройник не у мойки;
--  C  заглушка ниже тройника в столбе; тройник в шахте (выше ряда опоры), а заглушки над ним нет;
--  D  тройник закреплён не у мойки;
--  E  тройник у мойки, а заглушки на нём нет;
--  F  ниппель едет в столбе или закреплён не над стояком;
--  Ca свинчены пары, которых нет в сборке: тройник или заглушка сидят на ниппеле.
-- opts.novice = true — мерка НОВИЧКА (docs/DESIGN.md §7, решение Lao 29.09): остаются только A (деталь больше не
-- попадёт в столб вообще: угол, зажата, запечатана, нечем поднять), B (выход стояка навсегда закрыт деталью без хода
-- наверх — фонтана нет), D (тройник навсегда закреплён не у мойки — выход в стену), E (тройник у мойки, а его верх
-- навсегда открыт в глухую шахту); C, F, Ca и N (неверный порядок, пара, место, «следующий толчок») — новичку не видны.
-- НЕ помечает (нужно несколько ходов вперёд): порядок деталей в очереди, ещё не въехавших в столб; заглушку,
-- уехавшую в лифт раньше, чем тройник переправлен; Лапидуса, запертого не на той стороне.
local R = require("core.rules")
local M = {}

function M.why(def, opts)
  opts = opts or {}
  return function(lvl, st)
    local P = lvl.pieces
    local k = {}
    for q, p in ipairs(P) do if p.tag then k[p.tag] = q end; if p.source then k.src = q end; if p.fixture then k.fix = q end end
    local src = P[k.src].start
    local sx = R.xy(lvl, src)
    local fixC = P[k.fix].start
    local fixedAt, pieceAt = {}, {}
    for q = 1, #st.pos do local c = st.pos[q]; if c ~= 0 then pieceAt[c] = q; if st.fixed[q] then fixedAt[c] = true end end end
    local function wall(c) return c == 0 or lvl.cell[c] == R.WALL end
    local function solid(c) return wall(c) or fixedAt[c] end
    local function inCol(c) return c ~= 0 and (R.xy(lvl, c)) == sx end
    local tq, pq, nq = k.tee, k.plug, k.nip
    local tc, pc, nc = st.pos[tq], st.pos[pq], st.pos[nq]
    local baseCell = lvl.nb[src][R.UP]
    local teeAtSink = false
    if st.fixed[tq] and tc ~= 0 then for d = 1, 4 do if lvl.nb[tc][d] == fixC then teeAtSink = true end end end
    if st.fixed[tq] and not teeAtSink then return "D" end
    if teeAtSink and not (pc == lvl.nb[tc][R.UP] and st.fixed[pq]) then return "E" end
    -- основание (верхняя закреплённая клетка столба над стояком) и опора (клетка над верхушкой струи)
    local base = src
    while true do local u = lvl.nb[base][R.UP]; if u ~= 0 and fixedAt[u] then base = u else break end end
    local firstJet = lvl.nb[base][R.UP]
    local topThread = P[pieceAt[base]].ports[R.UP]
    local sup = base
    for _ = 1, lvl.R + 1 do local u = lvl.nb[sup][R.UP]; if u == 0 or wall(u) then break end; sup = u end
    local _, supY = R.xy(lvl, sup)
    local nov = opts.novice
    -- C (знаток: неверный порядок в стопке — новичку не виден)
    if not nov and inCol(tc) and inCol(pc) and pc > tc then return "C" end
    if not nov and inCol(tc) and not st.fixed[tq] then
      local _, ty = R.xy(lvl, tc)
      if ty < supY and not (inCol(pc) and pc < tc) then return "C" end
    end
    -- F (знаток: ниппель не на своём месте)
    if not nov and st.fixed[nq] and nc ~= baseCell then return "F" end
    if not nov and not st.fixed[nq] and inCol(nc) then return "F" end
    -- Ca
    local function on(a, b) -- a сидит на b и свинчена с ним
      local ca, cb = st.pos[a], st.pos[b]
      if ca == 0 or cb == 0 or lvl.nb[cb][R.UP] ~= ca then return false end
      return (not st.fixed[a] and not st.fixed[b] and st.asm[a] == st.asm[b])
    end
    if not nov and (on(tq, nq) or on(pq, nq)) then return "Ca" end
    -- B
    local w = R.water(lvl, st, nil, true)
    local jetUp = false
    for _, L in ipairs(w.leaks) do if L.dir == R.UP and (R.xy(lvl, L.cell)) == sx then jetUp = true end end
    if not jetUp and not teeAtSink then return "B" end
    -- A и N: свободные сборки вне столба
    local body = {}
    for _, b in ipairs(st.body) do body[b] = true end
    local function reach(from, avoid)
      if solid(from) or avoid[from] then return false end
      local seen, q, h = { [from] = true }, { from }, 1
      while h <= #q do
        local u = q[h]; h = h + 1
        if body[u] then return true end
        for d = 1, 4 do
          local v = lvl.nb[u][d]
          if v ~= 0 and not seen[v] and not solid(v) and not avoid[v] then seen[v] = true; q[#q + 1] = v end
        end
      end
      return false
    end
    local function keyOf(cells) local t = {}; for i, c in ipairs(cells) do t[i] = c end; table.sort(t); return table.concat(t, ",") end
    -- 0 — не войдёт в столб; 1 — войдёт только туда, где прикрутится к основанию; 2 — войдёт и поедет
    local function entry(q)
      local mem = {}
      for r = 1, #st.pos do if st.pos[r] ~= 0 and not st.fixed[r] and st.asm[r] == st.asm[q] then mem[#mem + 1] = r end end
      local selfSet = {}
      for _, r in ipairs(mem) do selfSet[r] = true end
      local c0 = {}
      for i, r in ipairs(mem) do c0[i] = st.pos[r] end
      local function fall(cells)
        while true do
          local down = {}
          for i, c in ipairs(cells) do
            local b = lvl.nb[c][R.DOWN]
            if b == 0 or solid(b) then return cells end
            if pieceAt[b] and not selfSet[pieceAt[b]] and not body[b] then return cells end
            down[i] = b
          end
          cells = down
        end
      end
      local function screws(cells)
        for i, c in ipairs(cells) do
          if c == firstJet then
            local dn = P[mem[i]].ports[R.DOWN]
            if dn and topThread and R.match(dn, topThread) then return true end
          end
        end
        return false
      end
      local best = 0
      local seen, qq, h = { [keyOf(c0)] = true }, { c0 }, 1
      while h <= #qq do
        local cells = qq[h]; h = h + 1
        local occ = {}
        for _, c in ipairs(cells) do occ[c] = true end
        for _, d in ipairs({ R.LEFT, R.RIGHT }) do
          local moved = {}
          for i, c in ipairs(cells) do local t = lvl.nb[c][d]; if t == 0 or solid(t) then moved = nil; break end; moved[i] = t end
          if moved then
            local okPush = false
            for _, c in ipairs(cells) do
              local back = lvl.nb[c][R.OPP[d]]
              if back ~= 0 and not occ[back] and reach(back, occ) then okPush = true; break end
            end
            if okPush then
              local enters = false
              for _, t in ipairs(moved) do if inCol(t) then enters = true end end
              if enters then
                if not screws(moved) then return 2 end
                best = 1
              else
                local r = fall(moved)
                local key = keyOf(r)
                if not seen[key] then seen[key] = true; qq[#qq + 1] = r end
              end
            end
          end
        end
      end
      return best
    end
    for _, q in ipairs({ tq, pq, nq }) do
      local c = st.pos[q]
      if c ~= 0 and not st.fixed[q] and not inCol(c) then
        local e = entry(q)
        if q == nq then
          if e == 0 then return "A" end
        elseif e == 0 then return "A"
        elseif e == 1 and not nov then return "N" end
      end
    end
    return false
  end
end

function M.make(def, opts)
  local f = M.why(def, opts)
  return function(lvl, st) return f(lvl, st) and true or false end
end

return M
