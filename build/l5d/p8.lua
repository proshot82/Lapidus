-- Квартира 5 «Лишний выход» — кандидат p8 (30.09.2026, build/l5d).
-- Лишний выход тройника смотрит влево — заглушка должна оказаться слева, когда тройник въедет на место.
-- Решение здесь не пишется.

-- Видимый проигрыш уровня (дополняет общую линейку tools/vislib.lua; мерка НОВИЧКА — только то, что видно без знания
-- финальной сборки): закреплённая деталь смотрит открытой резьбой в стену или в глухой бок / такую же резьбу
-- закреплённого — эта течь навсегда (как правило 1 в levels/04.lua).
local OPP = { 3, 4, 1, 2 }
local function visibleLoss(lvl, st)
  local occ = {}
  for q, p in ipairs(lvl.pieces) do
    if st.pos[q] ~= 0 then occ[st.pos[q]] = q elseif p.movable then return true end
  end
  for q, p in ipairs(lvl.pieces) do
    if p.movable and st.fixed[q] then
      for d = 1, 4 do
        local th = p.ports[d]
        if th then
          local t = lvl.nb[st.pos[q]][d]
          if t == 0 or lvl.cell[t] == 1 then return true end
          local r = occ[t]
          if r and st.fixed[r] then
            local th2 = lvl.pieces[r].ports[OPP[d]]
            if th2 == nil or th2 == th then return true end
          end
        end
      end
    end
  end
  return false
end

local function tagOf(lvl, tag) for q, p in ipairs(lvl.pieces) do if p.tag == tag then return q end end end
local function rowOf(lvl, c) return math.floor((c - 1) / lvl.W) + 1 end

-- Абляция РОЛИ «ступенька»: стоя на незакреплённой заглушке, Лапидус не поднимается выше, чем достаёт с пола
-- (ни одно звено не выше клетки «заглушка − Lmax»). Ходить по ней, толкать её, лежать на ней — можно.
local function noStep(lvl, st, ns)
  local pq = tagOf(lvl, "plug")
  local c = ns.pos[pq]
  if c == 0 or ns.fixed[pq] then return true end
  local above = lvl.nb[c][1]
  local on = false
  for _, b in ipairs(ns.body) do if b == above then on = true end end
  if not on then return true end
  local pr = rowOf(lvl, c)
  for _, b in ipairs(ns.body) do if rowOf(lvl, b) <= pr - lvl.Lmax then return false end end
  return true
end

return {
  visibleLoss = visibleLoss,
  id = 5, flat = 5, name = "Лишний выход",
  length = { 2, 5 }, pressure = 0, tile = "blue",
  target = { moves = { 15, 40 }, states = 300000, dead = 25, fb = 2 },
  grid = {
    "###########",
    "###.....###",
    "###.##.####",
    "###.##.####",
    "###.##.####",
    "##..#...###",
    "#........##",
    "###########",
  },
  objects = {
    { kind = "source", at = { 3, 6 }, ports = { down = "N" } },
    { kind = "fixture", what = "dryer", at = { 9, 7 }, ports = { left = "N" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 5, 2 }, ports = { up = "V", right = "V", left = "V" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { 6, 7 }, ports = { right = "N" } },
    { kind = "lapidus", cells = { { 8, 6 }, { 7, 6 }, { 7, 5 } }, head = 1 },
  },
  ablations = {
    { name = "без заглушки", remove = "plug" },
    { name = "ступенька запрещена (стоя на свободной заглушке, не выше, чем с пола)", filter = noStep },
  },
  controls = {
    { name = "контроль: тройник без лишнего выхода, заглушка есть (только ступенька)",
      mutate = function(d) for _, o in ipairs(d.objects) do if o.tag == "tee" then o.ports.left = nil end end end },
    { name = "контроль: тройник без лишнего выхода и без заглушки", remove = "plug",
      mutate = function(d) for _, o in ipairs(d.objects) do if o.tag == "tee" then o.ports.left = nil end end end },
  },
  texts = {
    request = "Полотенцесушитель холодный, носки мокрые. Пропажу второго носка прошу считать отдельной заявкой.",
    card = "card05",
    hints = {
      "У тройника три выхода, а занять вы можете два. Третий заткнёт только заглушка — и где она будет, когда потечёт?",
      "Ваш звонок очень важен для нас. Проверяем, не лишний ли у вас выход.",
      "Мастер выехал. Стремянку он с собой не возит.",
    },
  },
}
