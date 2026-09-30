-- build/l3d/s2.lua — кв. 3, доводка 30.09: левая часть как в levels/03.lua (сдвинута на ряд вниз); финал: стояк над шахтой.

-- Видимый проигрыш (правило v1 из build/l3c/REPORT.md). Смытое мыло само по себе НЕ проигрыш — одно мыло по
-- замыслу уходит в слив (поле washOk: инструментам нельзя считать любую смытую деталь проигрышем).
-- Проиграно, если
--   (1) где-то (кроме ступеньки) лежит мыло, которое заклинило: ни с одной стороны его не толкнуть;
--   (2) или всё оставшееся мыло бесполезно на вид: смыто, заклинило или лежит на полу в кармане у слива,
--       откуда его можно только столкнуть в слив.
local STEP_X, STEP_Y = 7, 8 -- низ шахты под мойкой: здесь мыло и нужно
local OPP = { 3, 4, 1, 2 }
local function visibleLoss(lvl, st)
  local step = (STEP_Y - 1) * lvl.W + STEP_X
  local fixedAt, soapAt, soaps = {}, {}, {}
  for q, p in ipairs(lvl.pieces) do
    local c = st.pos[q]
    if c ~= 0 then
      if st.fixed[q] then fixedAt[c] = true end
      if p.porcelain then soapAt[c] = true; soaps[#soaps + 1] = c end
    end
  end
  if #soaps == 0 then return true end
  local function wall(c) return c == 0 or lvl.cell[c] == 1 or fixedAt[c] == true end
  local function pit(c) return c ~= 0 and lvl.cell[c] == 2 end
  local function below(c) return lvl.nb[c][3] end
  local function resting(c) -- лежит на стене (или на мыле, которое лежит на стене), а не на Лапидусе
    local b = below(c)
    if wall(b) then return true end
    if soapAt[b] then return resting(b) end
    return false
  end
  local function frozen(c) -- ни с одной стороны не толкнуть: с той стороны стена (ногам не встать) или упор
    if not resting(c) then return false end
    for d = 1, 4 do
      local pc, tc = lvl.nb[c][OPP[d]], lvl.nb[c][d]
      if not wall(pc) and not pit(pc) and not wall(tc) then return false end
    end
    return true
  end
  local function pocket(c) -- на полу, по полу — только в стену или в слив, края полки нет
    if not wall(below(c)) then return false end
    for _, d in ipairs({ 2, 4 }) do
      local n = lvl.nb[c][d]
      while n ~= 0 and not wall(n) do
        if n == step then return false end
        local b = below(n)
        if pit(b) then break end
        if not wall(b) and not soapAt[b] then return false end
        n = lvl.nb[n][d]
      end
    end
    return true
  end
  for _, c in ipairs(soaps) do if c ~= step and frozen(c) then return true end end
  for _, c in ipairs(soaps) do if c == step or not (frozen(c) or pocket(c)) then return false end end
  return true
end

-- Абляции РОЛИ (фильтры ходов, как в levels/05.lua и levels/06.lua): каждая запрещает один приём цепочки.
local function soapAbove(lvl, s, c)
  local up = lvl.nb[c][1]
  for q, p in ipairs(lvl.pieces) do if p.porcelain and s.pos[q] == up then return true end end
  return false
end
-- «подставку не выбить»: нельзя смыть мыло, пока на нём лежит другое мыло
local function noKick(lvl, st, ns)
  for q, p in ipairs(lvl.pieces) do
    if p.porcelain and st.pos[q] ~= 0 and ns.pos[q] == 0 and soapAbove(lvl, st, st.pos[q]) then return false end
  end
  return true
end
-- «мыло на мыло не ляжет»: запрещено состояние, где мыло стоит прямо на другом мыле
local function noStack(lvl, st, ns)
  for q, p in ipairs(lvl.pieces) do
    if p.porcelain and ns.pos[q] ~= 0 and soapAbove(lvl, ns, ns.pos[q]) then return false end
  end
  return true
end
-- «мост запрещён»: мыло не может лежать на Лапидусе прямо над сливом
local function noBridge(lvl, st, ns)
  local body = {}
  for _, c in ipairs(ns.body) do body[c] = true end
  for q, p in ipairs(lvl.pieces) do
    local c = ns.pos[q]
    if p.porcelain and c ~= 0 then
      local d = lvl.nb[c][3]
      if body[d] and lvl.cell[lvl.nb[d][3]] == 2 then return false end
    end
  end
  return true
end
-- «подъёмник запрещён»: ногами нельзя толкнуть мыло вверх
local function noLift(lvl, st, ns)
  for q, p in ipairs(lvl.pieces) do
    if p.porcelain and st.pos[q] ~= 0 and ns.pos[q] ~= 0 and ns.pos[q] == lvl.nb[st.pos[q]][1] then return false end
  end
  return true
end

return {
  visibleLoss = visibleLoss,
  washOk = true, -- одно мыло уходит в слив по замыслу: проигрыш решает visibleLoss, а не «смыта деталь»
  id = 3, flat = 3, name = "Мыло",
  length = { 2, 5 }, pressure = 0, tile = "mustard",
  target = { moves = { 15, 40 }, states = 100000, dead = 35, fb = 2 },
  grid = {
    "###########",
    "######.####",
    "######.####",
    "######...##",
    "##...#.####",
    "##.#.#.####",
    "#......####",
    "###....####",
    "#####~#####",
  },
  objects = {
    { at = { 7, 2 }, kind = "source", ports = { down = "V" } },
    { at = { 9, 4 }, kind = "fixture", ports = { left = "N" }, what = "sink" },
    { at = { 4, 5 }, kind = "porcelain", tag = "soap" },
    { at = { 5, 8 }, kind = "porcelain", tag = "soap" },
    { cells = { { 4, 8 }, { 4, 7 }, { 3, 7 }, { 2, 7 } }, head = 4, kind = "lapidus" },
  },
  ablations = {
    { name = "без фаянса", remove = "soap" },
    { name = "подставку не выбить", filter = noKick },
    { name = "мыло на мыло не ляжет", filter = noStack },
    { name = "мост запрещён", filter = noBridge },
    { name = "подъёмник запрещён", filter = noLift },
  },
  texts = {
    request = "Гора посуды. Воды нет. Гора растёт.",
    card = "card03", -- вкладыш нового правила на экране заявки (§5)
    hints = {
      "Нижнее мыло — не ступенька, а подставка: выбейте его ногами в слив, когда на нём лежит верхнее.",
      "Ваш звонок очень важен для нас. Проверяем, на чём у вас держится мыло.",
      "Мастер выехал. Мыльница у него всегда при себе.",
    },
  },
}
