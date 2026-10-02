-- core/rules.lua
-- «Лапидус. Ни капли» — детерминированное ядро правил (дизайн-документ, §3–§4).
-- Без зависимостей от LÖVE: этот файл исполняют игра, солвер (luajit) и автоплей.
-- Всё, чего здесь нет, в игре не существует.

local R = {}
R.VERSION = "1.0.0"

-- Направления: 1 вверх, 2 вправо, 3 вниз, 4 влево. Ось y растёт вниз.
local UP, RIGHT, DOWN, LEFT = 1, 2, 3, 4
local DX = { 0, 1, 0, -1 }
local DY = { -1, 0, 1, 0 }
local OPP = { 3, 4, 1, 2 }
R.UP, R.RIGHT, R.DOWN, R.LEFT = UP, RIGHT, DOWN, LEFT
R.DX, R.DY, R.OPP = DX, DY, OPP
R.DIRNAME = { "up", "right", "down", "left" }
R.DIRINDEX = { up = 1, right = 2, down = 3, left = 4 }

local EMPTY, WALL, PIT = 0, 1, 2
R.EMPTY, R.WALL, R.PIT = EMPTY, WALL, PIT
R.MAX_SETTLE = 64

local floor = math.floor
local char, byte, concat = string.char, string.byte, table.concat
local tremove, tinsert, tsort = table.remove, table.insert, table.sort

local KINDS = { source = true, fixture = true, stub = true, pipe = true, fitting = true, porcelain = true }
R.KINDS = KINDS

-- Все 8 ходов: ноги ×4, голова ×4. Смена активного конца ходом не является.
R.MOVES = {}
for m = 1, 8 do
  R.MOVES[m] = { which = (m <= 4) and "heel" or "head", dir = (m - 1) % 4 + 1 }
end
function R.moveName(m)
  local mm = R.MOVES[m]
  return mm.which .. ":" .. R.DIRNAME[mm.dir]
end
function R.moveCode(which, dir)
  return (which == "heel" and 0 or 4) + dir
end
function R.parseMove(s)
  local w, d = s:match("^(%a+):(%a+)$")
  assert(w == "head" or w == "heel", "bad move " .. tostring(s))
  return R.moveCode(w, assert(R.DIRINDEX[d], "bad dir " .. tostring(s)))
end

-- Н входит в В и наоборот; одинаковые резьбы не свинчиваются.
local function match(a, b)
  return (a == "N" and b == "V") or (a == "V" and b == "N")
end
R.match = match

-- ================================================================== уровень

function R.compile(def)
  local grid = assert(def.grid, "level: grid missing")
  local H = #grid
  local W = #grid[1]
  assert(W * H <= 255, "level: grid too large for state encoding")
  local lvl = {
    def = def, W = W, H = H, N = W * H,
    cell = {}, nb = {},
    Lmin = def.length[1], Lmax = def.length[2],
    R = def.pressure or 0,
    pieces = {},
  }
  assert(lvl.Lmin >= 2 and lvl.Lmax >= lvl.Lmin, "level: bad length range")
  for y = 1, H do
    local row = grid[y]
    assert(#row == W, "level: row " .. y .. " has width " .. #row .. ", expected " .. W)
    for x = 1, W do
      local ch = row:sub(x, x)
      local i = (y - 1) * W + x
      if ch == "#" then lvl.cell[i] = WALL
      elseif ch == "~" then lvl.cell[i] = PIT
      elseif ch == "." then lvl.cell[i] = EMPTY
      else error("level: bad grid char '" .. ch .. "' at " .. x .. "," .. y) end
    end
  end
  for i = 1, lvl.N do
    local x = (i - 1) % W + 1
    local y = floor((i - 1) / W) + 1
    local t = {}
    for d = 1, 4 do
      local nx, ny = x + DX[d], y + DY[d]
      if nx >= 1 and nx <= W and ny >= 1 and ny <= H then t[d] = (ny - 1) * W + nx else t[d] = 0 end
    end
    lvl.nb[i] = t
  end
  local lap
  for _, o in ipairs(def.objects) do
    if o.kind == "lapidus" then
      assert(not lap, "level: two lapidus objects")
      lap = o
    else
      assert(KINDS[o.kind], "level: unknown kind " .. tostring(o.kind))
      local p = { kind = o.kind, what = o.what, tag = o.tag, ports = {}, nports = 0 }
      for _, side in ipairs(R.DIRNAME) do
        local th = o.ports and o.ports[side]
        if th then
          assert(th == "N" or th == "V", "level: bad thread " .. tostring(th))
          p.ports[R.DIRINDEX[side]] = th
          p.nports = p.nports + 1
        end
      end
      for side in pairs(o.ports or {}) do assert(R.DIRINDEX[side], "level: bad side " .. tostring(side)) end
      p.movable = (o.kind == "fitting" or o.kind == "porcelain")
      p.porcelain = (o.kind == "porcelain")
      p.source = (o.kind == "source")
      p.fixture = (o.kind == "fixture")
      p.x, p.y = o.at[1], o.at[2]
      p.start = (p.y - 1) * W + p.x
      assert(lvl.cell[p.start] == EMPTY, "level: object on non-empty cell at " .. p.x .. "," .. p.y)
      lvl.pieces[#lvl.pieces + 1] = p
    end
  end
  assert(#lvl.pieces <= 127, "level: too many pieces")
  assert(lap, "level: no lapidus")
  local cells = lap.cells
  assert(lap.head == 1 or lap.head == #cells, "level: lapidus head must be the first or the last cell")
  local body = {}
  if lap.head == #cells then
    for i = 1, #cells do body[i] = (cells[i][2] - 1) * W + cells[i][1] end
  else
    for i = #cells, 1, -1 do body[#body + 1] = (cells[i][2] - 1) * W + cells[i][1] end
  end
  lvl.lapStart = body -- тело хранится от ног (1) к голове (n)
  return lvl
end

function R.xy(lvl, i) return (i - 1) % lvl.W + 1, floor((i - 1) / lvl.W) + 1 end
function R.idx(lvl, x, y) return (y - 1) * lvl.W + x end

local function dirBetween(lvl, from, to)
  local t = lvl.nb[from]
  for d = 1, 4 do if t[d] == to then return d end end
  return nil
end
R.dirBetween = dirBetween

-- ================================================================== состояние
-- st = { body = {клетки от ног к голове}, pos = {клетка детали или 0, если смыло},
--        asm = {номер сборки}, fixed = {закреплена ли}, dead = Лапидуса смыло }

local function cloneState(st)
  local b, p, a, f = {}, {}, {}, {}
  local body, pos, asm, fixed = st.body, st.pos, st.asm, st.fixed
  for i = 1, #body do b[i] = body[i] end
  for q = 1, #pos do p[q] = pos[q]; a[q] = asm[q]; f[q] = fixed[q] end
  return { body = b, pos = p, asm = a, fixed = f, dead = st.dead }
end
R.clone = cloneState

function R.key(st)
  local t = { char(#st.body + (st.dead and 128 or 0)) }
  local body = st.body
  for i = 1, #body do t[#t + 1] = char(body[i]) end
  local pos, asm, fixed = st.pos, st.asm, st.fixed
  for q = 1, #pos do
    if pos[q] == 0 then
      t[#t + 1] = "\0\0"
    else
      t[#t + 1] = char(pos[q], asm[q] + (fixed[q] and 128 or 0))
    end
  end
  return concat(t)
end

function R.decode(lvl, k)
  local b0 = byte(k, 1)
  local n = b0 % 128
  local st = { body = {}, pos = {}, asm = {}, fixed = {}, dead = b0 >= 128 }
  for i = 1, n do st.body[i] = byte(k, 1 + i) end
  local o = 1 + n
  for q = 1, #lvl.pieces do
    local c, a = byte(k, o + 1, o + 2)
    st.pos[q] = c
    if c == 0 then
      st.asm[q] = q
      st.fixed[q] = false
    else
      st.fixed[q] = a >= 128
      st.asm[q] = a % 128
    end
    o = o + 2
  end
  return st
end

local function occupancy(st)
  local piece, bodyAt = {}, {}
  local pos = st.pos
  for q = 1, #pos do
    local c = pos[q]
    if c ~= 0 then piece[c] = q end
  end
  local body = st.body
  for i = 1, #body do bodyAt[body[i]] = i end
  return piece, bodyAt
end
R.occupancy = occupancy

-- Клетка конца, направление его резьбы (наружу, прочь от шеи) и тип резьбы.
-- Голова — гайка (В), ноги — штуцер (Н).
local function endInfo(lvl, st, which)
  local b = st.body
  local n = #b
  if which == "head" then
    return b[n], dirBetween(lvl, b[n - 1], b[n]), "V"
  else
    return b[1], dirBetween(lvl, b[2], b[1]), "N"
  end
end
R.endInfo = endInfo

-- Номер закреплённой детали, в которую прикручен конец, или nil.
local function endScrew(lvl, st, piece, which)
  local c, d, th = endInfo(lvl, st, which)
  local t = lvl.nb[c][d]
  if t == 0 then return nil end
  local q = piece[t]
  if q and st.fixed[q] and match(lvl.pieces[q].ports[OPP[d]], th) then return q end
  return nil
end
R.endScrew = endScrew

-- ================================================================== перемещения

-- Толчок цепочки подвижных сборок на клетку. Упор в стену, закреплённое
-- или тело Лапидуса — отказ без изменений.
local function pushAssemblies(lvl, st, piece, bodyAt, a0, d)
  local pos, asm, fixed = st.pos, st.asm, st.fixed
  local np = #pos
  local inset = { [a0] = true }
  local stack = { a0 }
  while #stack > 0 do
    local a = stack[#stack]
    stack[#stack] = nil
    for q = 1, np do
      local c = pos[q]
      if c ~= 0 and not fixed[q] and asm[q] == a then
        local t = lvl.nb[c][d]
        if t == 0 or lvl.cell[t] == WALL or bodyAt[t] then return false end
        local r = piece[t]
        if r then
          if fixed[r] then return false end
          local ar = asm[r]
          if not inset[ar] then
            inset[ar] = true
            stack[#stack + 1] = ar
          end
        end
      end
    end
  end
  for q = 1, np do
    local c = pos[q]
    if c ~= 0 and not fixed[q] and inset[asm[q]] then pos[q] = lvl.nb[c][d] end
  end
  return true
end

-- Сдвиг неприкрученного Лапидуса струёй целиком. Он ничего не толкает.
local function shiftLapidus(lvl, st, piece, bodyAt, d)
  local b = st.body
  for i = 1, #b do
    local t = lvl.nb[b[i]][d]
    if t == 0 or lvl.cell[t] == WALL then return false end
    if not bodyAt[t] and piece[t] then return false end
  end
  for i = 1, #b do b[i] = lvl.nb[b[i]][d] end
  return true
end

-- ================================================================== резьба

-- Подвижное + подвижное → одна сборка навсегда; подвижное + закреплённое →
-- сборка закреплена навсегда. Концы Лапидуса прикручиваются вычисляемо (endScrew).
local function threads(lvl, st, piece)
  local P = lvl.pieces
  local pos, asm, fixed = st.pos, st.asm, st.fixed
  local np = #pos
  local changed = false
  local again = true
  while again do
    again = false
    for q = 1, np do
      local c = pos[q]
      if c ~= 0 then
        local ports = P[q].ports
        for d = 1, 4 do
          local th = ports[d]
          if th then
            local t = lvl.nb[c][d]
            local r = (t ~= 0) and piece[t] or nil
            if r and match(th, P[r].ports[OPP[d]]) then
              local fq, fr = fixed[q], fixed[r]
              if fq ~= fr then
                local a = fq and asm[r] or asm[q]
                for k = 1, np do
                  if pos[k] ~= 0 and not fixed[k] and asm[k] == a then fixed[k] = true end
                end
                changed, again = true, true
              elseif (not fq) and asm[q] ~= asm[r] then
                local a1, a2 = asm[q], asm[r]
                local lo = (a1 < a2) and a1 or a2
                local hi = (a1 < a2) and a2 or a1
                for k = 1, np do
                  if pos[k] ~= 0 and not fixed[k] and asm[k] == hi then asm[k] = lo end
                end
                changed, again = true, true
              end
            end
          end
        end
      end
    end
  end
  return changed
end

-- Всё, что оказалось в сливе, смыло. Сборку смывает целиком.
local function wash(lvl, st)
  local changed = false
  local b = st.body
  if not st.dead then
    for i = 1, #b do
      if lvl.cell[b[i]] == PIT then
        st.dead = true
        changed = true
        break
      end
    end
  end
  local pos, asm, fixed = st.pos, st.asm, st.fixed
  local np = #pos
  for q = 1, np do
    local c = pos[q]
    if c ~= 0 and lvl.cell[c] == PIT then
      local a = asm[q]
      for k = 1, np do
        if pos[k] ~= 0 and not fixed[k] and asm[k] == a then pos[k] = 0 end
      end
      changed = true
    end
  end
  return changed
end

-- ================================================================== вода

-- Мокрая сеть: закреплённое, связанное резьбами со стояком; Лапидус пропускает
-- воду насквозь, если хотя бы один его конец прикручен к мокрому.
function R.water(lvl, st, piece, ignoreLap)
  piece = piece or occupancy(st)
  local P = lvl.pieces
  local pos, fixed = st.pos, st.fixed
  local wet = {}
  local queue = {}
  for q = 1, #P do
    if P[q].source and pos[q] ~= 0 then
      wet[q] = true
      queue[#queue + 1] = q
    end
  end
  local headQ, heelQ, headC, heelC, headD, heelD
  if (not ignoreLap) and (not st.dead) then
    headC, headD = endInfo(lvl, st, "head")
    heelC, heelD = endInfo(lvl, st, "heel")
    headQ = endScrew(lvl, st, piece, "head")
    heelQ = endScrew(lvl, st, piece, "heel")
  end
  local lapWet = false
  local qi = 1
  while qi <= #queue do
    local q = queue[qi]
    qi = qi + 1
    local c = pos[q]
    local ports = P[q].ports
    for d = 1, 4 do
      local th = ports[d]
      if th then
        local t = lvl.nb[c][d]
        local r = (t ~= 0) and piece[t] or nil
        if r and fixed[r] and (not wet[r]) and match(th, P[r].ports[OPP[d]]) then
          wet[r] = true
          queue[#queue + 1] = r
        end
      end
    end
    if (not lapWet) and (q == headQ or q == heelQ) then
      lapWet = true
      if headQ and not wet[headQ] then wet[headQ] = true; queue[#queue + 1] = headQ end
      if heelQ and not wet[heelQ] then wet[heelQ] = true; queue[#queue + 1] = heelQ end
    end
  end
  local leaks = {}
  for q = 1, #P do
    if wet[q] and not P[q].fixture then
      local c = pos[q]
      local ports = P[q].ports
      for d = 1, 4 do
        local th = ports[d]
        if th then
          local t = lvl.nb[c][d]
          local ok = false
          if t ~= 0 then
            local r = piece[t]
            if r and fixed[r] and match(th, P[r].ports[OPP[d]]) then ok = true
            elseif q == headQ and t == headC then ok = true
            elseif q == heelQ and t == heelC then ok = true end
          end
          if not ok then leaks[#leaks + 1] = { cell = c, dir = d, piece = q } end
        end
      end
    end
  end
  if lapWet then
    if not headQ then leaks[#leaks + 1] = { cell = headC, dir = headD, lapidus = "head" } end
    if not heelQ then leaks[#leaks + 1] = { cell = heelC, dir = heelD, lapidus = "heel" } end
  end
  local nf, nwet = 0, 0
  for q = 1, #P do
    if P[q].fixture and pos[q] ~= 0 then
      nf = nf + 1
      if wet[q] then nwet = nwet + 1 end
    end
  end
  return {
    wet = wet, lapWet = lapWet, leaks = leaks, headQ = headQ, heelQ = heelQ,
    fixtures = nf, wetFixtures = nwet,
  }
end

-- Победа: все приборы мокрые, нет протечек, и без Лапидуса хотя бы один прибор сухой.
function R.status(lvl, st)
  if st.dead then return { dead = true, win = false, leaks = {}, fixtures = 0, wetFixtures = 0, wet = {} } end
  local piece = occupancy(st)
  local w = R.water(lvl, st, piece)
  local win = false
  if w.fixtures > 0 and w.wetFixtures == w.fixtures and #w.leaks == 0 then
    local w2 = R.water(lvl, st, piece, true)
    win = w2.wetFixtures < w2.fixtures
  end
  w.win = win
  return w
end

function R.isWin(lvl, st)
  if st.dead then return false end
  return R.status(lvl, st).win
end

-- ================================================================== напор и струи

local function computeJets(lvl, st, piece, bodyAt, w)
  local jets = {}
  local anchored = (w.headQ ~= nil) or (w.heelQ ~= nil)
  if lvl.R <= 0 then return jets, anchored end
  for i = 1, #w.leaks do
    local L = w.leaks[i]
    local cells = {}
    local t = L.cell
    for _ = 1, lvl.R do
      t = lvl.nb[t][L.dir]
      if t == 0 or lvl.cell[t] == WALL then break end
      local r = piece[t]
      if r and st.fixed[r] then break end
      if anchored and bodyAt[t] then break end
      cells[#cells + 1] = t
    end
    jets[#jets + 1] = { cell = L.cell, dir = L.dir, cells = cells, lapidus = L.lapidus }
  end
  return jets, anchored
end

-- Струи текущего состояния (для рендера и подсказок).
function R.jets(lvl, st)
  if st.dead then return {} end
  local piece, bodyAt = occupancy(st)
  local w = R.water(lvl, st, piece)
  local jets = computeJets(lvl, st, piece, bodyAt, w)
  return jets
end

-- Струя вверх — столб: всё в столбе и на клетке над верхушкой стоит.
local function jetSupport(lvl, jets)
  local sup = nil
  for i = 1, #jets do
    local j = jets[i]
    if j.dir == UP and #j.cells > 0 then
      sup = sup or {}
      for k = 1, #j.cells do sup[j.cells[k]] = true end
      local top = lvl.nb[j.cells[#j.cells]][UP]
      if top ~= 0 then sup[top] = true end
    end
  end
  return sup
end

-- Встречные толчки гасят друг друга; при толчках по двум осям — только вертикальный.
local function resolveDir(vx, vy)
  if vy < 0 then return UP elseif vy > 0 then return DOWN
  elseif vx > 0 then return RIGHT elseif vx < 0 then return LEFT end
  return nil
end

local function applyJets(lvl, st, jets, anchored)
  if #jets == 0 then return false end
  local piece, bodyAt = occupancy(st)
  local pos, asm, fixed = st.pos, st.asm, st.fixed
  local np = #pos
  local vx, vy = {}, {}
  local lx, ly, lhit = 0, 0, false
  for i = 1, #jets do
    local j = jets[i]
    local seen = {}
    local seenL = false
    for k = 1, #j.cells do
      local c = j.cells[k]
      local r = piece[c]
      if r and not fixed[r] then
        local a = asm[r]
        if not seen[a] then
          seen[a] = true
          vx[a] = (vx[a] or 0) + DX[j.dir]
          vy[a] = (vy[a] or 0) + DY[j.dir]
        end
      end
      if (not anchored) and (not seenL) and bodyAt[c] then
        seenL = true
        lx, ly, lhit = lx + DX[j.dir], ly + DY[j.dir], true
      end
    end
  end
  -- тела в фиксированном порядке: по верхней-левой клетке (сверху вниз, слева направо)
  local bodies = {}
  local added = {}
  for q = 1, np do
    local a = asm[q]
    if pos[q] ~= 0 and not fixed[q] and vx[a] and not added[a] then
      added[a] = true
      local d = resolveDir(vx[a], vy[a])
      if d then
        local top = 1e9
        for k = 1, np do
          if pos[k] ~= 0 and not fixed[k] and asm[k] == a and pos[k] < top then top = pos[k] end
        end
        bodies[#bodies + 1] = { a = a, d = d, top = top }
      end
    end
  end
  if lhit then
    local d = resolveDir(lx, ly)
    if d then
      local top = 1e9
      for i = 1, #st.body do
        if st.body[i] < top then top = st.body[i] end
      end
      bodies[#bodies + 1] = { lap = true, d = d, top = top }
    end
  end
  tsort(bodies, function(x, y) return x.top < y.top end)
  local moved = false
  for i = 1, #bodies do
    local B = bodies[i]
    piece, bodyAt = occupancy(st)
    if B.lap then
      if shiftLapidus(lvl, st, piece, bodyAt, B.d) then moved = true end
    else
      if pushAssemblies(lvl, st, piece, bodyAt, B.a, B.d) then moved = true end
    end
  end
  return moved
end

-- ================================================================== гравитация

-- Предмет стоит, если хоть одна его клетка лежит на стене, закреплённом или на том,
-- что стоит само. Лапидус стоит так же — или если прикручен хоть один конец.
-- Всё, что не стоит, падает на одну клетку одновременно и целиком.
local function gravity(lvl, st, sup)
  local piece, bodyAt = occupancy(st)
  local pos, asm, fixed = st.pos, st.asm, st.fixed
  local np = #pos
  local cell, nb = lvl.cell, lvl.nb
  local supA = {}
  local lapSup = st.dead or (endScrew(lvl, st, piece, "head") ~= nil) or (endScrew(lvl, st, piece, "heel") ~= nil)
  local changed = true
  while changed do
    changed = false
    for q = 1, np do
      local c = pos[q]
      if c ~= 0 and not fixed[q] then
        local a = asm[q]
        if not supA[a] then
          local s = (sup ~= nil) and (sup[c] == true)
          if not s then
            local bl = nb[c][DOWN]
            if bl == 0 or cell[bl] == WALL then
              s = true
            else
              local r = piece[bl]
              if r then
                if fixed[r] or (asm[r] ~= a and supA[asm[r]]) then s = true end
              elseif bodyAt[bl] and lapSup then
                s = true
              end
            end
          end
          if s then
            supA[a] = true
            changed = true
          end
        end
      end
    end
    if not lapSup then
      local b = st.body
      for i = 1, #b do
        local c = b[i]
        local s = (sup ~= nil) and (sup[c] == true)
        if not s then
          local bl = nb[c][DOWN]
          if bl == 0 or cell[bl] == WALL then
            s = true
          elseif not bodyAt[bl] then
            local r = piece[bl]
            if r and (fixed[r] or supA[asm[r]]) then s = true end
          end
        end
        if s then
          lapSup = true
          changed = true
          break
        end
      end
    end
  end
  local fell = false
  for q = 1, np do
    local c = pos[q]
    if c ~= 0 and not fixed[q] and not supA[asm[q]] then
      pos[q] = nb[c][DOWN]
      fell = true
    end
  end
  if not lapSup then
    local b = st.body
    for i = 1, #b do b[i] = nb[b[i]][DOWN] end
    fell = true
  end
  return fell
end

-- ================================================================== цикл устаканивания

-- Резьба → струи (при напоре) → гравитация, пока всё не замрёт.
-- Возвращает false, если за R.MAX_SETTLE шагов не успокоилось (уровень бракуется).
function R.settle(lvl, st, trace)
  if wash(lvl, st) and trace then trace[#trace + 1] = { kind = "wash", state = cloneState(st) } end
  if st.dead then return true end
  for _ = 1, R.MAX_SETTLE do
    local piece, bodyAt = occupancy(st)
    local c1 = threads(lvl, st, piece)
    local c2, c3 = false, false
    local sup = nil
    if lvl.R > 0 then
      local w = R.water(lvl, st, piece)
      local jets, anchored = computeJets(lvl, st, piece, bodyAt, w)
      sup = jetSupport(lvl, jets)
      c2 = applyJets(lvl, st, jets, anchored)
      if c2 then wash(lvl, st) end
    end
    if not st.dead then
      c3 = gravity(lvl, st, sup)
      if c3 then wash(lvl, st) end
    end
    if trace and (c1 or c2 or c3) then
      trace[#trace + 1] = { kind = "settle", state = cloneState(st) }
    end
    if st.dead then return true end
    if not (c1 or c2 or c3) then return true end
  end
  return false
end

-- ================================================================== ход

-- which: "head" | "heel"; d: 1..4. Возвращает новое состояние, вид хода и признак
-- устойчивости, либо nil и причину отказа. Ход атомарен: всё проверяется до исполнения.
function R.move(lvl, st0, which, d, trace)
  if st0.dead then return nil, "dead" end
  local st = cloneState(st0)
  local piece, bodyAt = occupancy(st)
  local b = st.body
  local n = #b
  local e, neck
  if which == "head" then e, neck = b[n], b[n - 1] else e, neck = b[1], b[2] end
  local t = lvl.nb[e][d]
  if t == 0 or lvl.cell[t] == WALL then return nil, "wall" end
  local kind
  if t == neck then
    if n <= lvl.Lmin then return nil, "short" end
    if which == "head" then b[n] = nil else tremove(b, 1) end
    kind = "compress"
  else
    if bodyAt[t] then return nil, "self" end
    local q = piece[t]
    if q and st.fixed[q] then return nil, "fixed" end
    local sliding = false
    if n >= lvl.Lmax then
      local other = (which == "head") and "heel" or "head"
      if endScrew(lvl, st, piece, other) then return nil, "taut" end
      sliding = true
    end
    if q then
      if which == "head" and lvl.pieces[q].porcelain then return nil, "soap" end
      if not pushAssemblies(lvl, st, piece, bodyAt, st.asm[q], d) then return nil, "blocked" end
      kind = sliding and "push_slide" or "push_stretch"
    else
      kind = sliding and "slide" or "stretch"
    end
    if which == "head" then
      if sliding then tremove(b, 1) end
      b[#b + 1] = t
    else
      if sliding then b[#b] = nil end
      tinsert(b, 1, t)
    end
  end
  if trace then trace[#trace + 1] = { kind = kind, which = which, dir = d, state = cloneState(st) } end
  local stable = R.settle(lvl, st, trace)
  return st, kind, stable
end

-- ================================================================== начало уровня и проверка

local function rawState(lvl)
  local st = { body = {}, pos = {}, asm = {}, fixed = {}, dead = false }
  for i = 1, #lvl.lapStart do st.body[i] = lvl.lapStart[i] end
  for q, p in ipairs(lvl.pieces) do
    st.pos[q] = p.start
    st.asm[q] = q
    st.fixed[q] = not p.movable
  end
  return st
end

function R.newState(lvl)
  local st = rawState(lvl)
  local ok = R.settle(lvl, st)
  assert(ok, "level: initial settle does not converge")
  return st
end

function R.validate(lvl)
  local errs, warns = {}, {}
  local W, H = lvl.W, lvl.H
  for i = 1, lvl.N do
    local x, y = R.xy(lvl, i)
    if x == 1 or x == W or y == 1 or y == H then
      local c = lvl.cell[i]
      if c == EMPTY or (c == PIT and y ~= H) then
        errs[#errs + 1] = "border cell " .. x .. "," .. y .. " must be wall (pit only in the bottom row)"
      end
    end
  end
  local occ = {}
  local b = lvl.lapStart
  if #b < lvl.Lmin or #b > lvl.Lmax then errs[#errs + 1] = "lapidus length out of range" end
  for i = 1, #b do
    if lvl.cell[b[i]] ~= EMPTY then errs[#errs + 1] = "lapidus on non-empty cell" end
    if occ[b[i]] then errs[#errs + 1] = "lapidus overlaps itself" end
    occ[b[i]] = "L"
    if i > 1 and not dirBetween(lvl, b[i - 1], b[i]) then errs[#errs + 1] = "lapidus cells not adjacent" end
  end
  local nsrc, nfix = 0, 0
  for q, p in ipairs(lvl.pieces) do
    if occ[p.start] then errs[#errs + 1] = "overlap at piece " .. q end
    occ[p.start] = q
    if p.source then nsrc = nsrc + 1 end
    if p.fixture then
      nfix = nfix + 1
      if p.nports ~= 1 then errs[#errs + 1] = "fixture " .. q .. " must have exactly one port" end
    end
    if p.porcelain and p.nports > 0 then errs[#errs + 1] = "porcelain " .. q .. " must have no threads" end
    if (not p.porcelain) and p.nports == 0 then errs[#errs + 1] = "piece " .. q .. " has no threads" end
  end
  if nsrc == 0 then errs[#errs + 1] = "no source" end
  if nfix == 0 then errs[#errs + 1] = "no fixture" end
  if #errs == 0 then
    local s0 = rawState(lvl)
    local k0 = R.key(s0)
    local ok = R.settle(lvl, s0)
    if not ok then errs[#errs + 1] = "initial settle unstable" end
    if R.key(s0) ~= k0 then warns[#warns + 1] = "initial layout is not at rest" end
    if s0.dead then errs[#errs + 1] = "lapidus starts washed away" end
  end
  return errs, warns
end

return R
