-- qvis.lua — видимый проигрыш для семейства «надставка фонтана» (переходник — на ниппель в основание),
-- для экспериментов. local V = dofile("build/l7c/c_p2b_plus/qvis.lua"); def.visibleLoss = V.make(def, opts)
-- Правила (одной фразой каждое, «с одного взгляда» или «следующим толчком»):
--  A  деталь (или свинченная пара) на полу, которую уже не довести туда, где она нужна: заглушку и тройник — ни в одну
--     клетку струи, ниппель — в клетку над стояком; путь вдоль ряда упирается в стену/закреплённое, толкать не из чего
--     (нет клетки для толкающего конца, куда Лапидус может пройти в обход детали); подвижные детали на пути не в счёт
--     (их можно толкать впереди), падения с уступов учитываются;
--  Aa свободный переходник уже не попадёт на ниппель: лежит на полу в нижнем ряду (с пола его не поднять, а на ниппель
--     он может только лечь сверху или войти в струю сразу над ним) — при ниппеле ещё не в основании;
--  B  фонтана вверх нет, а тройник не у мойки;
--  C  тройник в шахте (выше комнаты), а заглушки над ним нет: в однополосной шахте заглушку над тройник уже не поднять;
--     заглушка ниже тройника в столбе;
--  D  тройник закреплён не у мойки;
--  E  тройник у мойки, а заглушки на нём нет;
--  F  ниппель или переходник едут в стопке (вверх из стопки не вернуться), закреплены не в основании, или переходник
--     не на ниппеле, когда ниппель уже в основании и клетка над ним занята/закрыта (opts.adpStackVisible — считать
--     «переходник в стопке» видимым; это самое спорное: роль переходника и есть «ага»);
--  N  ниппель уже в основании, а заглушка или тройник ещё вне столба.
local R = require("core.rules")
local M = {}

function M.why(def, opts)
  opts = opts or {}
  return function(lvl, st)
    local P = lvl.pieces
    local k = {}
    for q, p in ipairs(P) do if p.tag then k[p.tag] = q end; if p.source then k.src = q end; if p.fixture then k.fix = q end end
    local src = P[k.src].start
    local sx, sy = R.xy(lvl, src)
    local W = lvl.W
    local fixedAt, pieceAt = {}, {}
    for q = 1, #st.pos do local c = st.pos[q]; if c ~= 0 then pieceAt[c] = q; if st.fixed[q] then fixedAt[c] = true end end end
    local function wall(c) return c == 0 or lvl.cell[c] == R.WALL end
    local function solid(c) return wall(c) or fixedAt[c] end
    local function inCol(c) return c ~= 0 and (R.xy(lvl, c)) == sx end
    -- основание: верхняя закреплённая клетка столба над стояком; первая клетка струи — над ней
    local base = src
    while true do local u = lvl.nb[base][R.UP]; if u ~= 0 and fixedAt[u] then base = u else break end end
    local firstJet = lvl.nb[base][R.UP]
    local _, fy = R.xy(lvl, firstJet)
    local jetTopY = fy - (lvl.R - 1)
    local tq, pq, aq, nq = k.tee, k.plug, k.adp, k.nip
    local tc, pc, ac, nc = st.pos[tq], st.pos[pq], st.pos[aq], st.pos[nq]
    local fixC = P[k.fix].start
    local teeAtSink = false
    if st.fixed[tq] and tc ~= 0 then for d = 1, 4 do if lvl.nb[tc][d] == fixC then teeAtSink = true end end end
    -- D
    if st.fixed[tq] and not teeAtSink then return "D" end
    -- E
    if teeAtSink then
      local above = lvl.nb[tc][R.UP]
      if not (pc == above and st.fixed[pq]) then return "E" end
    end
    -- «в шахте»: клетка столба, по бокам стены/мойка
    local function inShaft(c)
      if not inCol(c) then return false end
      local l, r = lvl.nb[c][R.LEFT], lvl.nb[c][R.RIGHT]
      return (wall(l) or l == fixC) and (wall(r) or r == fixC)
    end
    -- C
    if inCol(tc) and not st.fixed[tq] then
      if inShaft(tc) and not (inCol(pc) and pc < tc) then return "C1" end
    end
    if inCol(tc) and inCol(pc) and pc > tc then return "C2" end
    -- F: ниппель
    local nipInBase = st.fixed[nq] and nc ~= 0 and inCol(nc) and nc == lvl.nb[src][R.UP]
    if st.fixed[nq] and not nipInBase then return "F1" end
    if not st.fixed[nq] and inCol(nc) then return "F2" end
    -- F: переходник
    local adpOnNip = false
    if ac ~= 0 and nc ~= 0 and ac == lvl.nb[nc][R.UP] then
      adpOnNip = (st.fixed[aq] and st.fixed[nq]) or (not st.fixed[aq] and not st.fixed[nq] and st.asm[aq] == st.asm[nq])
    end
    if st.fixed[aq] and not adpOnNip then return "F3" end
    if opts.adpStackVisible and not st.fixed[aq] and inCol(ac) and not adpOnNip then return "F4" end
    if nipInBase and not adpOnNip then
      -- переходник должен ещё войти в клетку над ниппелем: если она занята закреплённым или переходник в столбе — видно
      if inCol(ac) then return "F5" end
    end
    -- N
    if nipInBase and adpOnNip then
      if not inCol(tc) or not inCol(pc) then return "N" end
    end
    -- B
    local w = R.water(lvl, st, nil, true)
    local jetUp = false
    for _, L in ipairs(w.leaks) do if L.dir == R.UP and (R.xy(lvl, L.cell)) == sx then jetUp = true end end
    if not jetUp and not teeAtSink then return "B" end
    -- A / Aa: свободные сборки на полу
    local body = {}
    for _, b in ipairs(st.body) do body[b] = true end
    local function reachable(from, avoid)
      -- можно ли Лапидусу попасть в клетку from (обходя клетки avoid): заливка от тела по пустым клеткам
      if solid(from) then return false end
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
    -- куда упадёт одиночная деталь из клетки c (по пустым клеткам вниз)
    local function rest(c)
      while true do
        local b = lvl.nb[c][R.DOWN]
        if b == 0 or solid(b) or (pieceAt[b] and not body[b]) then return c end
        c = b
      end
    end
    -- может ли одиночная деталь из клетки c дойти толчками вдоль рядов (с падениями) до клетки столба,
    -- удовлетворяющей okCell(cell); pushOK — есть ли клетка для толкающего конца позади
    local function canReach(c0, okCell, avoidSelf)
      local seen, q, h = { [c0] = true }, { c0 }, 1
      while h <= #q do
        local c = q[h]; h = h + 1
        local x = R.xy(lvl, c)
        if x == sx then if okCell(c) then return true end
        else
          local d = (x < sx) and R.RIGHT or R.LEFT
          local back = lvl.nb[c][R.OPP[d]]
          local avoid = { [c] = true }
          if back ~= 0 and not solid(back) and reachable(back, avoid) then
            local t = lvl.nb[c][d]
            if t ~= 0 and not solid(t) then
              local r = (R.xy(lvl, t) == sx) and t or rest(t)
              if not seen[r] then seen[r] = true; q[#q + 1] = r end
            end
          end
        end
      end
      return false
    end
    local function jetCell(c) local _, y = R.xy(lvl, c); return y <= fy and y >= jetTopY end
    local function baseCell(c) return c == firstJet end
    -- заглушка, тройник: должны войти в клетку струи
    for _, q in ipairs({ pq, tq }) do
      local c = st.pos[q]
      if c ~= 0 and not st.fixed[q] and not inCol(c) then
        local alone = true
        for r = 1, #st.pos do if r ~= q and st.pos[r] ~= 0 and not st.fixed[r] and st.asm[r] == st.asm[q] then alone = false end end
        if alone and not canReach(c, jetCell, q) then return "A1" end
      end
    end
    -- ниппель (с переходником или без): в клетку над стояком, пока она первая клетка струи
    if not st.fixed[nq] and nc ~= 0 and not inCol(nc) then
      -- ниппель: путь вдоль его ряда к клетке над стояком без стен и закреплённого (толкать можно и через пару)
      local x, y = R.xy(lvl, nc)
      local _, by = R.xy(lvl, firstJet)
      if y ~= by or solid(firstJet) then return "A2" end
      local d = (x < sx) and R.RIGHT or R.LEFT
      local t = nc
      while true do
        t = lvl.nb[t][d]
        if t == 0 or solid(t) then return "A2" end
        if t == firstJet then break end
      end
    end
    -- Aa: свободный переходник в нижнем ряду (ниппель ещё не в основании)
    if not st.fixed[aq] and not adpOnNip and ac ~= 0 and not inCol(ac) then
      local _, ay = R.xy(lvl, ac)
      if ay == sy - 1 then return "Aa" end
    end
    return false
  end
end

function M.make(def, opts)
  local f = M.why(def, opts)
  return function(lvl, st) return f(lvl, st) and true or false end
end

return M
