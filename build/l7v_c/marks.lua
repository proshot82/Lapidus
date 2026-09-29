-- build/l7v_c/marks.lua — разметки видимого проигрыша слепого скептика для кандидата кв. 7 (c_p2b_plus/c7).
-- Возвращает функции-правила; копии уровня c7_newbie.lua / c7_expert.lua подключают их к def.visibleLoss.
-- Мерка новичка (самая широкая, ещё честная): правила файла (A, B, D, E) плюс
--  N1. подножие запечатано: ниппель прикручен в основании (его резьба Н смотрит вверх в первую клетку струи), а нужная
--      деталь (тройник или заглушка, обе с резьбой В снизу) лежит на уровне пола вне столба — карточка: деталь,
--      вошедшая в первую клетку струи с подходящей резьбой, прикручивается; иначе, чем через подножие, с пола
--      в столб не попасть → «лежит там, где её нечем поднять»;
--  N2. карман запечатан самими деталями: чтобы толкнуть деталь к столбу, Лапидусу надо встать за ней, а пройти
--      туда можно только сквозь стоящие на твёрдом детали (в т. ч. её саму); висящие в струе детали проходимы —
--      их можно поднять снизу (кран). Считается как правило A файла, но при подходе к клетке толкающего
--      стоящие на твёрдом детали — препятствие (с учётом толчка цепочкой: толкать можно из-за ряда деталей).
-- Мерка знатока: плюс неверный порядок очереди в коридоре (ниппель левее тройника или заглушки; тройник левее
--  заглушки) — знаток знает порядок стопки и что ниппель идёт последним.
local R = require("core.rules")
local UP, RIGHT, DOWN, LEFT = 1, 2, 3, 4
local OPP = { 3, 4, 1, 2 }
local M = {}

local function find(lvl)
  local t = {}
  for q, p in ipairs(lvl.pieces) do
    if p.source then t.src = q elseif p.fixture then t.fix = q end
    if p.tag then t[p.tag] = q end
  end
  return t
end
local function xy(lvl, c) return (c - 1) % lvl.W + 1, math.floor((c - 1) / lvl.W) + 1 end

function M.N1(lvl, st)
  local k = find(lvl)
  if not st.fixed[k.nip] or st.pos[k.nip] == 0 then return false end
  local sx, sy = xy(lvl, lvl.pieces[k.src].start)
  if st.pos[k.nip] ~= lvl.nb[lvl.pieces[k.src].start][UP] then return false end -- ниппель именно в основании
  for _, q in ipairs({ k.tee, k.plug }) do
    local c = st.pos[q]
    if c ~= 0 and not st.fixed[q] then
      local x, y = xy(lvl, c)
      if x ~= sx and y >= sy - lvl.R then return true end -- на уровне пола (ряды 6–7), вне столба
    end
  end
  return false
end

-- N2: как правило A файла, но подход к клетке толкающего — только по пустым клеткам (стоящие на твёрдом детали —
-- препятствие), клетка толкающего — за цепочкой деталей.
function M.N2(lvl, st)
  local P = lvl.pieces
  local k = find(lvl)
  local sx = xy(lvl, P[k.src].start)
  local fixedAt, pieceAt = {}, {}
  for q = 1, #st.pos do local c = st.pos[q]; if c ~= 0 then pieceAt[c] = q; if st.fixed[q] then fixedAt[c] = true end end end
  local function wall(c) return c == 0 or lvl.cell[c] == 1 end
  local function solid(c) return wall(c) or fixedAt[c] end
  local function inCol(c) return c ~= 0 and (xy(lvl, c)) == sx end
  local body = {}
  for _, b in ipairs(st.body) do body[b] = true end
  -- стоит ли деталь на твёрдом (рекурсивно через детали под ней)
  local grounded = {}
  local function isGrounded(c, seen)
    if grounded[c] ~= nil then return grounded[c] end
    seen = seen or {}
    if seen[c] then return false end
    seen[c] = true
    local q = pieceAt[c]
    local a = st.asm[q]
    local g = false
    for r = 1, #st.pos do
      if st.pos[r] ~= 0 and not st.fixed[r] and st.asm[r] == a then
        local b = lvl.nb[st.pos[r]][DOWN]
        if solid(b) then g = true break end
        if pieceAt[b] and st.asm[pieceAt[b]] ~= a and isGrounded(b, seen) then g = true break end
      end
    end
    grounded[c] = g
    return g
  end
  local function obstacle(c) -- для подхода Лапидуса
    if solid(c) then return true end
    local q = pieceAt[c]
    if q and not st.fixed[q] and isGrounded(c) then return true end
    return false
  end
  -- стоящую на твёрдом деталь можно «пройти», толкнув её перед собой, если за ней свободно и там, куда она
  -- упадёт, она не окажется в сокобан-углу (иначе проход стоит детали — это уже видимая потеря)
  local function pushThrough(v, d)
    -- Лапидус входит в клетку v в направлении d, деталь уезжает в w = nb[v][d] (свободна по построению BFS),
    -- затем падает; в столбе струи она не падает, а висит над верхушкой
    local w = lvl.nb[v][d]
    if w == 0 or solid(w) or pieceAt[w] then return false end
    local wx = xy(lvl, w)
    local _, sy = xy(lvl, P[k.src].start)
    if wx == sx then
      local top = R.idx(lvl, sx, sy - lvl.R - 1)
      if pieceAt[top] or body[top] then return false end
      w = top
    else
      while true do
        local b = lvl.nb[w][DOWN]
        if b == 0 or solid(b) or pieceAt[b] or body[b] then break end
        w = b
      end
    end
    for _, e in ipairs({ LEFT, RIGHT }) do
      local a, bk = lvl.nb[w][e], lvl.nb[w][OPP[e]]
      if a ~= 0 and not solid(a) and bk ~= 0 and not solid(bk) then return true end
    end
    return false
  end
  local function reach(from, avoid)
    if obstacle(from) or avoid[from] then return false end
    local seen, q, h = { [from] = true }, { from }, 1
    while h <= #q do
      local u = q[h]; h = h + 1
      if body[u] then return true end
      for d = 1, 4 do
        local v = lvl.nb[u][d]
        if v ~= 0 and not seen[v] and not avoid[v] then
          local pass = not obstacle(v)
          -- BFS идёт от клетки толкающего к телу; Лапидус же движется навстречу: из-за v в сторону OPP[d], деталь — в u
          if not pass and not solid(v) and (d == LEFT or d == RIGHT) and pushThrough(v, OPP[d]) then pass = true end
          if pass then seen[v] = true; q[#q + 1] = v end
        end
      end
    end
    return false
  end
  local function keyOf(cells) local t = {}; for i, c in ipairs(cells) do t[i] = c end; table.sort(t); return table.concat(t, ",") end
  local function canEnter(q0)
    local mem, selfSet, c0 = {}, {}, {}
    for r = 1, #st.pos do if st.pos[r] ~= 0 and not st.fixed[r] and st.asm[r] == st.asm[q0] then mem[#mem + 1] = r; selfSet[r] = true end end
    for i, r in ipairs(mem) do c0[i] = st.pos[r] end
    local function fall(cells)
      while true do
        local down = {}
        for i, c in ipairs(cells) do
          local b = lvl.nb[c][DOWN]
          if b == 0 or solid(b) then return cells end
          if pieceAt[b] and not selfSet[pieceAt[b]] and not body[b] then return cells end
          down[i] = b
        end
        cells = down
      end
    end
    local first = true
    local seen, qq, h = { [keyOf(c0)] = true }, { c0 }, 1
    while h <= #qq do
      local cells = qq[h]; h = h + 1
      local occ = {}
      for _, c in ipairs(cells) do occ[c] = true end
      for _, d in ipairs({ LEFT, RIGHT }) do
        local moved = {}
        for i, c in ipairs(cells) do local t = lvl.nb[c][d]; if t == 0 or solid(t) then moved = nil; break end; moved[i] = t end
        if moved then
          local okPush = false
          for _, c in ipairs(cells) do
            -- клетка толкающего: за цепочкой стоящих подряд деталей позади (в сторону OPP[d])
            local back = lvl.nb[c][OPP[d]]
            if first then
              while back ~= 0 and not occ[back] and pieceAt[back] and not fixedAt[back] and not body[back] do back = lvl.nb[back][OPP[d]] end
              if back ~= 0 and not occ[back] and not obstacle(back) and reach(back, occ) then okPush = true; break end
            else
              -- в будущем положении (после других толчков) — как в правиле файла: оптимистично, детали не в счёт
              if back ~= 0 and not occ[back] and not solid(back) then okPush = true; break end
            end
          end
          if okPush then
            for _, t in ipairs(moved) do if inCol(t) then return true end end
            local r = fall(moved)
            local key = keyOf(r)
            if not seen[key] then seen[key] = true; qq[#qq + 1] = r end
          end
        end
      end
      first = false
    end
    return false
  end
  for _, q in ipairs({ k.tee, k.plug, k.nip }) do
    local c = st.pos[q]
    if c ~= 0 and not st.fixed[q] and not inCol(c) and not canEnter(q) then return true end
  end
  return false
end

-- знаток: порядок очереди в коридоре (ряд стояка + 1) нарушен
function M.X1(lvl, st)
  local k = find(lvl)
  local _, sy = xy(lvl, lvl.pieces[k.src].start)
  local rowY = sy - 1
  local sx = xy(lvl, lvl.pieces[k.src].start)
  local function xr(q) local c = st.pos[q]; if c == 0 or st.fixed[q] then return nil end; local x, y = xy(lvl, c); if y == rowY and x > sx then return x end end
  local xt, xp, xn = xr(k.tee), xr(k.plug), xr(k.nip)
  if xn and ((xt and xn < xt) or (xp and xn < xp)) then return true end
  if xt and xp and xt < xp then return true end
  return false
end
return M
