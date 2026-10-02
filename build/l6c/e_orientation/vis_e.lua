-- vis_e.lua — честный «видимый проигрыш» для раскладок направления E (кв. 6), ред. 4.
-- (ред. 3: висящая над сливом пара — только если её уже нельзя сдвинуть; ред. 4: «стена» сзади — это и карман,
-- куда концу Лапидуса не встать, потому что шее рядом нет места.)
-- Одной фразой: свободная деталь (или свинченная пара) лежит на твёрдом там, откуда её уже не сдвинуть к стояку:
-- ниже ряда стояка (поднять нечем), в ряду стояка упёршись в стену с той стороны, откуда её надо толкать,
-- или зажата так (в том числе вися над сливом у стояка), что её нельзя толкнуть ни в какую сторону.
-- Смытые детали check.lua учитывает сам.
-- Не помечает (это «ага», а не взгляд): порядок деталей на полу, пару, свинченную не той стороной.
return function(lvl, st)
  local W = lvl.W
  local srcRow, pushDir
  for q, p in ipairs(lvl.pieces) do
    if p.source then
      srcRow = math.floor((p.start - 1) / W) + 1
      for d = 1, 4 do if p.ports[d] then pushDir = ({ 3, 4, 1, 2 })[d] end end
    end
  end
  local fixedAt = {}
  for k = 1, #st.pos do if st.pos[k] ~= 0 and st.fixed[k] then fixedAt[st.pos[k]] = true end end
  local function solid(c) return c == 0 or lvl.cell[c] == 1 or fixedAt[c] end
  -- клетка, куда может встать толкающий конец: не твёрдая, не слив и есть сосед для шеи (кроме самой детали)
  local function pusherOK(t, inSet)
    if solid(t) or lvl.cell[t] == 2 then return false end
    for d = 1, 4 do local u = lvl.nb[t][d]; if u ~= 0 and not inSet[u] and not solid(u) and lvl.cell[u] ~= 2 then return true end end
    return false
  end
  local asm = {}
  for q, p in ipairs(lvl.pieces) do
    local c = st.pos[q]
    if p.movable and c ~= 0 and not st.fixed[q] then
      local a = asm[st.asm[q]] or {}; asm[st.asm[q]] = a; a[#a + 1] = c
    end
  end
  for _, cells in pairs(asm) do
    local inSet = {}
    for _, c in ipairs(cells) do inSet[c] = true end
    local onHard, allRow, below, overPit, canUp = false, true, false, false, false
    local canL, canR = true, true
    local pushL, pushR = false, false
    for _, c in ipairs(cells) do
      local row = math.floor((c - 1) / W) + 1
      local b = lvl.nb[c][3]
      if not inSet[b] then
        if solid(b) then onHard = true; if row > srcRow then below = true end
        elseif lvl.cell[b] == 2 then overPit = true
        else canUp = true end
      end
      if row ~= srcRow then allRow = false end
      local l, r = lvl.nb[c][4], lvl.nb[c][2]
      if not inSet[r] then if solid(r) then canR = false end; if pusherOK(r, inSet) then pushL = true end end
      if not inSet[l] then if solid(l) then canL = false end; if pusherOK(l, inSet) then pushR = true end end
    end
    if onHard then
      if below then return true end
      local movable = canUp or (canR and pushR) or (canL and pushL)
      if not movable then return true end
      if allRow and pushDir and (pushDir == 2 or pushDir == 4) then
        if pushDir == 2 and not pushR then return true end
        if pushDir == 4 and not pushL then return true end
      end
    end
  end
  return false
end
