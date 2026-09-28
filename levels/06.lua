-- Квартира 6 «Намертво» (28.09.2026), ядро «муфтой вперёд» (build/l6c/e_orientation/r9.lua, второй поиск ядра).
-- Колонка висит под потолком на выступе (вход справа, В); стояк (вход слева, Н) — за двойным сливом.
-- Одна деталь двойной слив не перейдёт; свинченная пара переходит, но только муфтой вперёд, а ниппель лежит
-- «не с той стороны» муфты, и с пола его не поднять. Ложный план: ниппель в колонку, муфту в стояк.
-- Итоги поиска и проверки скептиком — build/l6c/README.md. Решение здесь не пишется.

-- Видимый проигрыш (vis_e ред. 4): свободная деталь (или свинченная пара) лежит на твёрдом там, откуда её уже
-- не сдвинуть к стояку. Порядок деталей на полу и пару «не той стороной» не помечает — это «ага».
local function visibleLoss(lvl, st)
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

-- Абляции РОЛИ приёмов (фильтры ходов, как в levels/05.lua)
-- «Пара не держит деталь над сливом»: запрещено состояние, где незакреплённая деталь висит над сливом
-- (держась за свинченную с ней соседку).
local function noBridge(lvl, st, ns)
  for q, p in ipairs(lvl.pieces) do
    local c = ns.pos[q]
    if p.movable and c ~= 0 and not ns.fixed[q] then
      local b = lvl.nb[c][3]
      if b ~= 0 and lvl.cell[b] == 2 then return false end
    end
  end
  return true
end
-- «Ниппель не переходит муфту поверху»: запрещено состояние, где свободный ниппель стоит в одном столбце с
-- незакреплённой муфтой выше неё (перенос через муфту — роль приёма «ниппель — за муфту»).
local function noOver(lvl, st, ns)
  local nq, cq
  for q, p in ipairs(lvl.pieces) do if p.tag == "nip" then nq = q elseif p.tag == "cpl" then cq = q end end
  local n, c = ns.pos[nq], ns.pos[cq]
  if n == 0 or c == 0 or ns.fixed[nq] or ns.fixed[cq] then return true end
  local W = lvl.W
  if (n - 1) % W == (c - 1) % W and n < c then return false end
  return true
end

return {
  visibleLoss = visibleLoss,
  id = 6, flat = 6, name = "Намертво",
  length = { 3, 5 }, pressure = 0, tile = "mustard",
  target = { moves = { 15, 40 }, states = 1000000, dead = 50, fb = 3 },
  grid = {
    "###########",
    "###.......#",
    "#.........#",
    "#.........#",
    "#######~~##",
  },
  objects = {
    { kind = "source", at = { 10, 4 }, ports = { left = "N" } },
    { kind = "fixture", what = "heater", at = { 4, 2 }, ports = { right = "V" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 4, 4 }, ports = { left = "V", right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 7, 3 }, ports = { left = "N", right = "N" } },
    { kind = "lapidus", cells = { { 7, 4 }, { 8, 4 }, { 9, 4 } }, head = 1 },
  },
  ablations = {
    { name = "без ниппеля", remove = "nip" },
    { name = "без муфты", remove = "cpl" },
    { name = "пара не держит муфту над сливом", filter = noBridge },
    { name = "ниппель не переходит муфту поверху", filter = noOver },
  },
  texts = {
    request = "Колонка не греет. Хожу дома в ушанке. Под ушанкой — вторая ушанка.",
    card = "card06", -- вкладыш «7 · Поднимает, но не носит» на экране заявки
    hints = {
      "Ниппель — не в колонку, а за спину муфте: через двойной слив они пройдут только парой, муфтой вперёд.",
      "Ваш звонок очень важен для нас. Проверяем, той ли стороной у вас свинчено.",
      "Мастер выехал. Шапку он снимает, не наклоняясь.",
    },
  },
}
