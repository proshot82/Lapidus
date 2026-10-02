-- verify_visW.lua — ШИРОКИЙ видимый проигрыш (проверка скептика): всё из visP, плюс
-- «муфта уже закреплена в стояке, а ноги Лапидуса не стоят вплотную к ней слева (с шеей на развилке)»:
-- кольцо разорвано, развернуться негде, а ногам нужно войти в муфту — верхняя граница «видимости».
local P = dofile("build/l6c/d_crane/visP.lua")
return function(lvl, st)
  if P(lvl, st) then return true end
  local qC
  for q, p in ipairs(lvl.pieces) do if p.tag == "C" then qC = q end end
  if st.fixed[qC] and st.pos[qC] ~= 0 then
    local W = lvl.W
    local feet, neck = st.body[1], st.body[2]
    local cx = st.pos[qC]
    if not (feet == cx - 1 and neck == cx - 2) then return true end
  end
  return false
end
