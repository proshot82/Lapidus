-- verify2_vis.lua — видимый проигрыш скептика для p2b (вторая проверка, 28.09.2026). Решений не содержит.
-- local V = dofile("build/l7c/b_lift_cargo/verify2_vis.lua"); def.visibleLoss = V.make(def, "honest")
-- Режимы:
--   "mine"   — разметка автора (A, B, C из p2b.lua) без изменений;
--   "base"   — mine + бесспорное: D (тройник прикручен не у мойки);
--   "honest" — самая широкая, по мнению скептика, ещё честная разметка: base +
--      E  тройник прикручен у мойки, а заглушка не на нём и не над ним в шахте (открытый верх смотрит в глухую шахту);
--      Ca переходник навсегда под тройником (свинчен с его низом или прикручен под ним): низ стопки снова «В», как у
--         стояка, — нужен ниппель, а для Лапидуса остаётся одна клетка;
--      Sr жёсткая сборка перегородила правую комнату во всю высоту, а Лапидус по свободным клеткам за неё не пройдёт:
--         отсюда её можно только отталкивать от столба (сокобан-тупик);
--      N  ниппель уже в основании фонтана, а тройник, заглушка или переходник ещё вне столба: всё, что теперь войдёт
--         в столб, прикрутится низом «В» к верху ниппеля «Н» (резьба сильнее струи).
--   "honest-N"  — honest без правила N (самое спорное: следствие на один ход вперёд);
--   "honest-Sr" — honest без правила Sr.
-- Порядок деталей, которые ещё только поедут, «переходник забыт в очереди», «заглушка на тройнике раньше переходника»
-- и «Лапидус заперт не на той стороне» НЕ помечаются: чтобы увидеть проигрыш, нужно несколько ходов вперёд.
local R = require("core.rules")
local M = {}

function M.make(def, mode)
  local authorVis = def.visibleLoss -- правила A, B, C автора (p2b.lua)
  local useD = mode ~= "mine"
  local honest = mode and mode:match("^honest") ~= nil
  local useE, useCa = honest, honest
  local useSr = honest and mode ~= "honest-Sr"
  local useN = honest and mode ~= "honest-N"
  return function(lvl, st)
    if authorVis(lvl, st) then return true end
    if mode == "mine" then return false end
    local P = lvl.pieces
    local k = {}
    for q, p in ipairs(P) do if p.tag then k[p.tag] = q end; if p.source then k.src = q end; if p.fixture then k.fix = q end end
    local sx = R.xy(lvl, P[k.src].start)
    local function inCol(c) return c ~= 0 and (R.xy(lvl, c)) == sx end
    local tq, pq, aq, nq = k.tee, k.plug, k.adp, k.nip
    local tc, pc, ac = st.pos[tq], st.pos[pq], st.pos[aq]
    local tAtFix = false
    if st.fixed[tq] and tc ~= 0 then
      for d = 1, 4 do if lvl.nb[tc][d] == st.pos[k.fix] then tAtFix = true end end
    end
    -- D: тройник прикручен не у мойки
    if useD and st.fixed[tq] and not tAtFix then return true end
    -- E: тройник у мойки, а заглушки на нём нет и она не над ним в шахте
    if useE and tAtFix then
      local above = lvl.nb[tc][R.UP]
      if not (pc ~= 0 and (pc == above or (inCol(pc) and pc < tc))) then return true end
    end
    -- Ca: переходник навсегда под тройником
    if useCa and tc ~= 0 and ac ~= 0 and ac == lvl.nb[tc][R.DOWN] then
      local joined = (not st.fixed[tq] and not st.fixed[aq] and st.asm[tq] == st.asm[aq]) or (st.fixed[tq] and st.fixed[aq])
      if joined then return true end
    end
    -- N: ниппель в основании, а кто-то из стопки ещё вне столба (и не прикручен)
    if useN and st.fixed[nq] then
      for _, q in ipairs({ tq, pq, aq }) do
        local c = st.pos[q]
        if c ~= 0 and not st.fixed[q] and not inCol(c) then return true end
      end
    end
    -- Sr: жёсткая сборка во всю высоту правой комнаты, Лапидус по свободным клеткам за неё не пройдёт
    if useSr then
      local occ = {}
      for q = 1, #st.pos do if st.pos[q] ~= 0 then occ[st.pos[q]] = q end end
      local body = {}
      for _, c in ipairs(st.body) do body[c] = true end
      -- заливка «Лапидус как точка»: от тела по пустым клеткам (не стена, не деталь)
      local reach, qq, h = {}, {}, 1
      for _, c in ipairs(st.body) do reach[c] = true; qq[#qq + 1] = c end
      while h <= #qq do
        local u = qq[h]; h = h + 1
        for d = 1, 4 do
          local v = lvl.nb[u][d]
          if v ~= 0 and not reach[v] and lvl.cell[v] ~= R.WALL and not occ[v] then reach[v] = true; qq[#qq + 1] = v end
        end
      end
      for x = sx + 1, lvl.W - 1 do
        -- клетки столбца x, открытые в обе стороны по горизонтали (коридор), и кто их занимает
        local asmId, full, any = nil, true, false
        for y = 1, lvl.H do
          local c = R.idx(lvl, x, y)
          if lvl.cell[c] ~= R.WALL then
            local l, r = lvl.nb[c][R.LEFT], lvl.nb[c][R.RIGHT]
            local corridor = l ~= 0 and r ~= 0 and lvl.cell[l] ~= R.WALL and lvl.cell[r] ~= R.WALL
            if corridor then
              any = true
              local q = occ[c]
              if not q or not P[q].movable or st.fixed[q] then full = false
              elseif asmId == nil then asmId = st.asm[q]
              elseif asmId ~= st.asm[q] then full = false end
            end
          end
        end
        if any and full and asmId then
          local behind = false
          for c in pairs(reach) do if (R.xy(lvl, c)) > x then behind = true; break end end
          if not behind then return true end
        end
      end
    end
    return false
  end
end

return M
