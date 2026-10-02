-- build/l7v_d/v_wide.lua — копия кандидата L7D с САМОЙ ШИРОКОЙ ещё честной разметкой новичка (слепой скептик, 29.09.2026).
-- К общей линейке (tools/vislib.lua) и правилам файла добавлено то, что новичок видит с одного взгляда по геометрии:
--  A) «запечатана в кармане»: незакреплённая деталь стоит в кармане слева — (2,6), (3,6) или (3,5): толкнуть её вправо
--     можно только из (2,6), куда уже не пройти (единственный вход в карман — через саму деталь);
--  B) «карман заперт стопкой»: обе детали незакреплены и стоят стопкой в (4,5)+(4,6), а Лапидус снаружи кармана —
--     толкать их вправо можно только из кармана, а оба входа в карман заняты ими же.
-- Проверено по графу: ни одно живое состояние этими правилами не помечается.
local def = dofile("build/l7c/d_tee_lift/L7D.lua")
local orig = def.visibleLoss
local function idx(lvl, x, y) return (y - 1) * lvl.W + x end
def.visibleLoss = function(lvl, st)
  if orig(lvl, st) then return true end
  local pocket = { [idx(lvl, 2, 6)] = true, [idx(lvl, 3, 6)] = true, [idx(lvl, 3, 5)] = true }
  local stack = { [idx(lvl, 4, 5)] = true, [idx(lvl, 4, 6)] = true }
  local inStack = 0
  for q, p in ipairs(lvl.pieces) do
    if p.movable and st.pos[q] ~= 0 and not st.fixed[q] then
      if pocket[st.pos[q]] then return true end
      if stack[st.pos[q]] then inStack = inStack + 1 end
    end
  end
  if inStack == 2 then
    for _, c in ipairs(st.body) do if pocket[c] then return false end end
    return true
  end
  return false
end
return def
