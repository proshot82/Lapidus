-- build/l7v_d/v_expert_noD.lua — мерка знатока без правила D (Лапидус в корыте при обеих деталях на месте остаётся скрытым).
local def = dofile("build/l7v_d/v_wide.lua")
local wide = def.visibleLoss
def.visibleLoss = function(lvl, st)
  if wide(lvl, st) then return true end
  local qe, qp
  for q, p in ipairs(lvl.pieces) do if p.what == "elbow" then qe = q elseif p.what == "plug" then qp = q end end
  return st.fixed[qe] and st.pos[qp] ~= 0 and not st.fixed[qp]
end
return def
