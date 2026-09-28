-- build/l3c/was.lua — «было»: нынешний levels/03.lua без изменений раскладки, но с честным видимым проигрышем v1
-- (то же правило, что в r2.lua) и washOk. Только для замеров «было»; решение здесь не пишется.

-- Видимый проигрыш (правило v1 из build/l3c/REPORT.md). Смытое мыло само по себе НЕ проигрыш — одно мыло по
-- замыслу уходит в слив (поле washOk: инструментам нельзя считать любую смытую деталь проигрышем).
-- Проиграно, если
--   (1) где-то (кроме ступеньки) лежит мыло, которое заклинило: ни с одной стороны его не толкнуть;
--   (2) или всё оставшееся мыло бесполезно на вид: смыто, заклинило или лежит на полу в кармане у слива,
--       откуда его можно только столкнуть в слив.
local STEP_X, STEP_Y = 7, 7 -- низ шахты под мойкой: здесь мыло и нужно
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

return {
  visibleLoss = visibleLoss,
  washOk = true,
  ablations = { { name = "без фаянса", remove = "soap" } },
  flat = 3,
  grid = {
    "###########",
    "#..#......#",
    "##.##..####",
    "#......####",
    "#.##...####",
    "#......####",
    "###....####",
    "#####~#####",
  },
  id = 3,
  length = { 2, 5 },
  name = "Мыло",
  objects = {
    { at = { 6, 2 }, kind = "source", ports = { right = "V" } },
    { at = { 10, 2 }, kind = "fixture", ports = { left = "N" }, what = "sink" },
    { at = { 3, 4 }, kind = "porcelain", tag = "soap" },
    { at = { 5, 7 }, kind = "porcelain", tag = "soap" },
    { cells = { { 6, 7 }, { 7, 7 }, { 7, 6 }, { 6, 6 } }, head = 4, kind = "lapidus" },
  },
  pressure = 0,
  target = { dead = 35, fb = 2, moves = { 25, 45 }, states = 100000 },
  tile = "mustard",
}
