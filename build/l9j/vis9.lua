-- build/l9j/vis9.lua — видимый проигрыш кандидатов раунда f (кв. 9): build/l9j/vis.lua (шов в стену, одноразьбовая
-- деталь на стояке/приборе) плюс правило скептика 02.10: тройник, окаменевший прямо на стояке, — видимый проигрыш
-- (его лишний выход смотрит в лаз над сливом, куда заглушку не донести; слив виден до хода).
local base = dofile("build/l9j/vis.lua")
local R = require("core.rules")
return function(lvl, st)
  if base(lvl, st) then return true end
  for q, p in ipairs(lvl.pieces) do
    if p.source then
      local top = lvl.nb[p.start][R.UP]
      for r, pr in ipairs(lvl.pieces) do
        if pr.movable and pr.nports >= 3 and st.fixed[r] and st.pos[r] == top then return true end
      end
    end
  end
  return false
end
