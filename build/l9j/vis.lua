-- build/l9j/vis.lua — честный видимый проигрыш кандидатов кв. 9, ТОЛЬКО добавка к общей линейке tools/vislib.lua.
-- Видимо проиграно «с одного взгляда», если:
--  1) прикрученная (окаменевшая) деталь смотрит открытой резьбой в стену, в глухой бок закреплённого или в такую же
--     резьбу другой закреплённой детали — шов, который никогда не закрыть (правило 1 из levels/05.lua, build/l6j/vis.lua);
--  2) одноразьбовая деталь (заглушка) прикручена прямо к стояку или к прибору — выход занят деталью, чья резьба явно
--     никуда не ведёт (DESIGN §7, мерка новичка).
-- Порядок деталей, «не та» пара и деталь на правдоподобном чужом порту НЕ помечаются (мерка новичка).
local OPP = { 3, 4, 1, 2 }
return function(lvl, st)
  local occ = {}
  for q = 1, #st.pos do if st.pos[q] ~= 0 then occ[st.pos[q]] = q end end
  for q, p in ipairs(lvl.pieces) do
    if p.movable and st.pos[q] ~= 0 and st.fixed[q] then
      for d = 1, 4 do
        local th = p.ports[d]
        if th then
          local t = lvl.nb[st.pos[q]][d]
          if t == 0 or lvl.cell[t] == 1 then return true end
          local r = occ[t]
          if r and st.fixed[r] then
            local th2 = lvl.pieces[r].ports[OPP[d]]
            if th2 == nil or th2 == th then return true end
            if p.nports == 1 and (lvl.pieces[r].source or lvl.pieces[r].fixture) then return true end
          end
        end
      end
    end
  end
  return false
end
