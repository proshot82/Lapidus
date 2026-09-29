-- build/l7v_d/v_expert.lua — копия кандидата L7D с меркой ЗНАТОКА (слепой скептик, 29.09.2026): всё из v_wide плюс то,
-- что видно, зная финальную сборку и правила струй:
--  C) угольник уже прикручен к тройнику, а заглушка ещё не на месте: попасть в боковой выход (6,7) она может только
--     сверху через (6,6) — первую клетку струи угольника, а резьбы к нему у неё нет, значит струя её унесёт в корыто;
--  D) обе детали на месте, а Лапидус неприкрученный целиком справа (x >= 7): к входу ванны сверху не подойти —
--     струя вдоль ряда 6 сносит вправо всё неприкрученное, опоры слева нет.
local def = dofile("build/l7v_d/v_wide.lua")
local wide = def.visibleLoss
local R = require("core.rules")
def.visibleLoss = function(lvl, st)
  if wide(lvl, st) then return true end
  local qe, qp
  for q, p in ipairs(lvl.pieces) do if p.what == "elbow" then qe = q elseif p.what == "plug" then qp = q end end
  if st.fixed[qe] and st.pos[qp] ~= 0 and not st.fixed[qp] then return true end
  if st.fixed[qe] and st.fixed[qp] then
    local piece = R.occupancy(st)
    if R.endScrew(lvl, st, piece, "head") or R.endScrew(lvl, st, piece, "heel") then return false end
    for _, c in ipairs(st.body) do if (c - 1) % lvl.W + 1 <= 6 then return false end end
    return true
  end
  return false
end
return def
