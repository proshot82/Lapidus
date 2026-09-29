-- tools/vislib.lua — общая линейка видимого проигрыша для всех уровней (29.09.2026, после критики мерки).
-- Считается по графу состояний одинаково для всех квартир; def.visibleLoss уровня может только расширять её.
--
-- Мерка новичка (по ней считаются ворота, docs/DESIGN.md §7) — видимо проиграно, если:
--   · смыта подвижная деталь (кроме уровней с def.washOk, где одна деталь уходит в слив по замыслу);
--   · смыта деталь, которая есть в выигрышной конфигурации («нужная»), — и при washOk тоже;
--   · нужная незакреплённая деталь стоит не на своём финальном месте и ни в одном достижимом будущем больше
--     не сдвинется (сокобан-угол, зажата — с учётом того, куда вообще может добраться Лапидус);
--   · нужная незакреплённая деталь «запечатана в кармане»: во всех достижимых будущих она может оказаться лишь
--     в нескольких клетках (не больше M.POCKET = 4), и её финального места среди них нет — ёрзает в тупике
--     (обобщение правила скептиков кв. 3 и 7, 29.09; дальние судьбы детали — «обречена по итогу» — это мерка знатока);
--   · сработало правило самого уровня def.visibleLoss(lvl, st).
-- Мерка знатока (для сведения): плюс то, что видно сравнением с единственной финальной сборкой, — деталь прикручена
--   не на своё место; две детали свинчены иначе, чем в финале (другим боком или другим взаимным положением);
--   любой следующий ход делает проигрыш видимым новичку. «Деталь уже никогда не попадёт на место» считается
--   отдельно (L.omni) — это всеведение, а не взгляд: у всех уровней она помечает почти все тупики.
-- Живые состояния ни одна мерка не помечает по построению (из живого состояния все детали доходят до места).
--
-- local V = require("tools.vislib"); local L = V.compute(lvl, G, def)
-- L.newbie[i], L.expert[i] — true, если состояние i видимо проиграно (для смытых Лапидусом, flag == 2, — nil).
local R = require("core.rules")
local M = { POCKET = 4 } -- 29.09, вечер: 3 → 4 после скептика кв. 7 (build/l7v_e): уровень стоял ровно на пороге, ниша была четвёртой клеткой

-- обратные рёбра графа (только между состояниями, где Лапидус не смыт)
local function reverseEdges(G)
  local n, ES, E, flag = G.n, G.eStart.p, G.edges.p, G.flag
  local cnt = {}
  for i = 1, n + 1 do cnt[i] = 0 end
  for i = 1, n do
    if flag[i] ~= 2 then
      for e = ES[i - 1], ES[i] - 1 do local j = E[e]; if flag[j] ~= 2 then cnt[j] = cnt[j] + 1 end end
    end
  end
  local start, s = {}, 1
  for i = 1, n do start[i] = s; s = s + cnt[i] end
  start[n + 1] = s
  local fill, rev = {}, {}
  for i = 1, n do fill[i] = start[i] end
  for i = 1, n do
    if flag[i] ~= 2 then
      for e = ES[i - 1], ES[i] - 1 do
        local j = E[e]
        if flag[j] ~= 2 then rev[fill[j]] = i; fill[j] = fill[j] + 1 end
      end
    end
  end
  return start, rev
end

-- все состояния, из которых достижимо хотя бы одно состояние-семя
local function backClosure(n, start, rev, seeds)
  local mark, q = {}, {}
  for i in pairs(seeds) do mark[i] = true; q[#q + 1] = i end
  local h = 1
  while h <= #q do
    local j = q[h]; h = h + 1
    for k = start[j], start[j + 1] - 1 do
      local i = rev[k]
      if not mark[i] then mark[i] = true; q[#q + 1] = i end
    end
  end
  return mark
end

function M.compute(lvl, G, def, good)
  M.liveSet = good
  local n, ES, E, flag = G.n, G.eStart.p, G.edges.p, G.flag
  local pos, fixed, sts = {}, {}, {}
  for i = 1, n do
    if flag[i] ~= 2 then
      local st = R.decode(lvl, G.keys[i])
      sts[i] = st
      pos[i], fixed[i] = st.pos, st.fixed
    end
  end
  local win = sts[G.firstWin]
  local needed = {}
  for q, p in ipairs(lvl.pieces) do
    if p.movable and win.pos[q] ~= 0 then needed[#needed + 1] = q end
  end
  local start, rev = reverseEdges(G)
  local canMove, canGoal, sealedBy = {}, {}, {}
  -- компоненты сильной связности (итеративный Тарьян) по рёбрам между несмытыми состояниями;
  -- компоненты выходят в обратном топологическом порядке (сначала стоки)
  local comp, order = {}, {}
  do
    local idx, low, onst, st, cnt = {}, {}, {}, {}, 0
    for root = 1, n do
      if flag[root] ~= 2 and not idx[root] then
        local call = { { root, ES[root - 1] } }
        cnt = cnt + 1; idx[root], low[root] = cnt, cnt; st[#st + 1] = root; onst[root] = true
        while #call > 0 do
          local top = call[#call]
          local v, e = top[1], top[2]
          if e < ES[v] then
            top[2] = e + 1
            local w = E[e]
            if flag[w] ~= 2 then
              if not idx[w] then
                cnt = cnt + 1; idx[w], low[w] = cnt, cnt; st[#st + 1] = w; onst[w] = true
                call[#call + 1] = { w, ES[w - 1] }
              elseif onst[w] and idx[w] < low[v] then low[v] = idx[w] end
            end
          else
            call[#call] = nil
            if #call > 0 then local u = call[#call][1]; if low[v] < low[u] then low[u] = low[v] end end
            if low[v] == idx[v] then
              local c = #order + 1
              order[c] = {}
              repeat local w = st[#st]; st[#st] = nil; onst[w] = nil; comp[w] = c; order[c][#order[c] + 1] = w until w == v
            end
          end
        end
      end
    end
  end
  local POCKET = M.POCKET
  -- для детали q: множество будущих клеток (до POCKET + 1 штук, дальше — «много») и есть ли среди них финальное место
  local function pocketSealed(q, goal)
    local cells, big, hasGoal = {}, {}, {}
    for c = 1, #order do
      local set, cntc, isBig, g = {}, 0, false, false
      local function add(x)
        if isBig or x == 0 or set[x] then return end
        set[x] = true; cntc = cntc + 1
        if x == goal then g = true end
        if cntc > POCKET then isBig = true end
      end
      for _, v in ipairs(order[c]) do add(pos[v][q]) end
      for _, v in ipairs(order[c]) do
        for e = ES[v - 1], ES[v] - 1 do
          local w = E[e]
          if flag[w] ~= 2 then
            local d = comp[w]
            if d ~= c then
              if big[d] then isBig = true
              else
                if hasGoal[d] then g = true end
                for x in pairs(cells[d]) do add(x) end
              end
            end
          end
          if isBig then break end
        end
        if isBig then break end
      end
      big[c], hasGoal[c], cells[c] = isBig, g, isBig and {} or set
    end
    local S = {}
    for i = 1, n do
      if flag[i] ~= 2 then
        local c, ci = pos[i][q], comp[i]
        if c ~= 0 and not fixed[i][q] and c ~= goal and not big[ci] and not hasGoal[ci] then S[i] = true end
      end
    end
    return S
  end
  for _, q in ipairs(needed) do
    local goal = win.pos[q]
    local mv, gl = {}, {}
    for i = 1, n do
      if flag[i] ~= 2 then
        local pi = pos[i][q]
        if pi == goal then gl[i] = true end
        for e = ES[i - 1], ES[i] - 1 do
          local j = E[e]
          if flag[j] ~= 2 and pos[j][q] ~= pi then mv[i] = true; break end
        end
      end
    end
    canMove[q] = backClosure(n, start, rev, mv)
    canGoal[q] = backClosure(n, start, rev, gl)
    sealedBy[q] = pocketSealed(q, goal)
  end
  local newbie, expert, omni = {}, {}, {}
  local counts = { frozen = 0, levelRule = 0, washed = 0, goal = 0 }
  for i = 1, n do
    if flag[i] ~= 2 then
      local st = sts[i]
      local lost, why = false, nil
      if not def.washOk then
        for q, p in ipairs(lvl.pieces) do if p.movable and st.pos[q] == 0 then lost, why = true, "washed" break end end
      end
      if not lost then
        for _, q in ipairs(needed) do
          local c = st.pos[q]
          if c == 0 then lost, why = true, "washed" break end
          if not st.fixed[q] and c ~= win.pos[q] and not canMove[q][i] then lost, why = true, "frozen" break end
          if sealedBy[q][i] then lost, why = true, "frozen" break end
        end
      end
      if not lost and def.visibleLoss and def.visibleLoss(lvl, st) then lost, why = true, "levelRule" end
      newbie[i] = lost
      if why then counts[why] = counts[why] + 1 end
      local om = lost
      if not om then
        for _, q in ipairs(needed) do if not canGoal[q][i] then om = true break end end
        if om then counts.goal = counts.goal + 1 end
      end
      omni[i] = om
    end
  end
  -- знаток: сравнение с финальной сборкой и «проигрыш вскрывается любым следующим ходом»
  local good = M.good or {}
  for i = 1, n do
    if flag[i] ~= 2 then
      local st, ex = sts[i], newbie[i]
      if not ex then
        for _, q in ipairs(needed) do
          if st.fixed[q] and (st.pos[q] ~= win.pos[q] or not win.fixed[q]) then ex = true break end
        end
      end
      if not ex then
        for a = 1, #needed do
          local q = needed[a]
          for b = a + 1, #needed do
            local r = needed[b]
            if st.pos[q] ~= 0 and st.pos[r] ~= 0 and not st.fixed[q] and st.asm[q] == st.asm[r]
               and (st.pos[r] - st.pos[q]) ~= (win.pos[r] - win.pos[q]) then ex = true break end
          end
          if ex then break end
        end
      end
      expert[i] = ex
    end
  end
  -- любой ход из мёртвого состояния ведёт в видимый новичку проигрыш (или смывает Лапидуса)
  local live = M.liveSet
  for i = 1, n do
    if flag[i] ~= 2 and not expert[i] and not (live and live[i] == 1) then
      local any, allVis = false, true
      for e = ES[i - 1], ES[i] - 1 do
        local j = E[e]
        any = true
        if flag[j] ~= 2 and not newbie[j] then allVis = false break end
      end
      if any and allVis then expert[i] = true end
    end
  end
  return { newbie = newbie, expert = expert, omni = omni, states = sts, counts = counts, needed = needed,
           canMove = canMove, sealedBy = sealedBy, win = win } -- последние три — для диагностики (build/l4d/why.lua)
end

-- доля скрытых, умная обезьяна и глубина скрытой ветки у пути — по заданной разметке (как в build/l6b/check.lua)
function M.measure(G, good, lostArr)
  local n, ES, E, flag = G.n, G.eStart.p, G.edges.p, G.flag
  local live, vis, hid = 0, 0, 0
  local hidden = {}
  for i = 1, n do
    if flag[i] ~= 2 then
      if good[i] == 1 then live = live + 1 elseif lostArr[i] then vis = vis + 1 else hid = hid + 1; hidden[i] = true end
    end
  end
  local opt = G.depth[G.firstWin]
  local T = 5 * opt
  local p, ok = { [1] = 1.0 }, 0
  for _ = 1, T do
    local np = {}
    for i, pr in pairs(p) do
      local cand = {}
      for e = ES[i - 1], ES[i] - 1 do
        local j = E[e]
        if flag[j] == 1 then cand[#cand + 1] = j elseif flag[j] ~= 2 and not lostArr[j] then cand[#cand + 1] = j end
      end
      if #cand == 0 then np[i] = (np[i] or 0) + pr else
        local share = pr / #cand
        for _, j in ipairs(cand) do if flag[j] == 1 then ok = ok + share else np[j] = (np[j] or 0) + share end end
      end
    end
    p = np
  end
  local smart = 100 * (1 - (1 - ok) ^ (1000 / T))
  local path, x = {}, G.firstWin
  while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
  table.insert(path, 1, 1)
  local function depthFrom(j)
    local d, q, h, maxd = { [j] = 0 }, { j }, 1, 0
    while h <= #q do
      local u = q[h]; h = h + 1
      for e = ES[u - 1], ES[u] - 1 do
        local v = E[e]
        if hidden[v] and d[v] == nil then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; q[#q + 1] = v end
      end
    end
    return maxd
  end
  local maxDeep, deepAt = 0, {}
  for k = 1, #path - 1 do
    local s = path[k]
    for e = ES[s - 1], ES[s] - 1 do
      local j = E[e]
      if hidden[j] then local d = depthFrom(j); if d > (deepAt[k - 1] or -1) then deepAt[k - 1] = d end; if d > maxDeep then maxDeep = d end end
    end
  end
  local dl = {}
  for k = 0, #path - 2 do if deepAt[k] then dl[#dl + 1] = k .. ":" .. deepAt[k] end end
  return { live = live, vis = vis, hid = hid, hiddenPct = 100 * hid / math.max(1, hid + live), smart = smart,
           maxDeep = maxDeep, deepList = table.concat(dl, " "), hidden = hidden, path = path, opt = opt }
end

return M
