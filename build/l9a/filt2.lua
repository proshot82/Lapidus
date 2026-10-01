-- build/l9a/filt2.lua — фильтры и мутации раунда 2 кв. 9 (g8+): узкие абляции роли гребёнки и контроли порядка.
local R = require("core.rules")
local F = dofile("build/l9a/filt.lua")
local F2 = {}
-- Структурная абляция «у гребёнки один выход вверх»: у дальней клетки гребёнки (m2) убирается выход вверх.
function F2.oneOutlet(d)
  for _, o in ipairs(d.objects) do if o.tag == "m2" then o.ports.up = nil end end
end
-- Узкая абляция «с гребня не сдвинуть вбок»: свободная деталь, стоявшая на гребне (клетке над верхушкой столба),
-- не переходит по горизонтали (скептик, build/l9v/abl.lua N.noRideMove).
function F2.noRideMove(lvl, st, ns)
  if ns.dead then return true end
  local _, top = F.columns(lvl, st)
  for q, p in ipairs(lvl.pieces) do
    local c, c2 = st.pos[q], ns.pos[q]
    if p.movable and c ~= 0 and not st.fixed[q] and top[c] and c2 ~= 0 then
      local x1 = R.xy(lvl, c); local x2 = R.xy(lvl, c2)
      if x1 ~= x2 then return false end
    end
  end
  return true
end
-- Контроль порядка: заглушка не закрепляется, пока тройник не закреплён (должен быть решаем — это и есть решение).
function F2.plugAfterTee(lvl, st, ns)
  if ns.dead then return true end
  local qp, qt = F.find(lvl, "plug"), F.find(lvl, "tee")
  if qp and qt and ns.fixed[qp] and not st.fixed[qp] and not ns.fixed[qt] then return false end
  return true
end
-- Абляция порядка «дальний фонтан закрыт до тройника»: заглушка обязана закрепиться раньше тройника
-- (запрещён переход, в котором тройник закрепляется, пока заглушка свободна). Должна быть нерешаема.
function F2.plugBeforeTee(lvl, st, ns)
  if ns.dead then return true end
  local qp, qt = F.find(lvl, "plug"), F.find(lvl, "tee")
  if qp and qt and ns.fixed[qt] and not st.fixed[qt] and not ns.fixed[qp] then return false end
  return true
end
-- Узкая абляция «удерживаемую в столбе деталь не сдвинуть вбок»: свободная деталь, стоявшая в клетке столба (не на гребне),
-- не переходит по горизонтали.
function F2.noSideFromHold(lvl, st, ns)
  if ns.dead then return true end
  local col = F.columns(lvl, st)
  for q, p in ipairs(lvl.pieces) do
    local c, c2 = st.pos[q], ns.pos[q]
    if p.movable and c ~= 0 and not st.fixed[q] and col[c] and c2 ~= 0 then
      local x1 = R.xy(lvl, c); local x2 = R.xy(lvl, c2)
      if x1 ~= x2 then return false end
    end
  end
  return true
end
-- Узкая абляция «с гребня на гребень нельзя»: свободная деталь не переходит с одного гребня прямо на другой.
function F2.noCrestToCrest(lvl, st, ns)
  if ns.dead then return true end
  local _, top1 = F.columns(lvl, st)
  local _, top2 = F.columns(lvl, ns)
  for q, p in ipairs(lvl.pieces) do
    local c, c2 = st.pos[q], ns.pos[q]
    if p.movable and c ~= 0 and c2 ~= 0 and not st.fixed[q] and top1[c] and top2[c2] and c ~= c2 then
      local _, y1 = R.xy(lvl, c); local _, y2 = R.xy(lvl, c2)
      if y1 == y2 then return false end
    end
  end
  return true
end
return F2
