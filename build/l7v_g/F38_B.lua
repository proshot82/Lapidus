-- build/l7v_g/F38_B.lua — F38 без изменений раскладки + правило §7 «деталь лежит там, где её нечем поднять»:
-- подвижная деталь на нижнем полу (строка 7) — видимо проиграно (фонтан бьёт из устья выше пола, Лапидус поднимает
-- только то, что лежит на нём, а под деталь на полу ему не подлезть).
local R = require("core.rules")
local def = dofile("build/l7f/F38.lua")
def.visibleLoss = function(lvl, st)
  for q, p in ipairs(lvl.pieces) do if p.movable and st.pos[q] ~= 0 and not st.fixed[q] then
    local _, y = R.xy(lvl, st.pos[q]); if y == 7 then return true end end end
  return false
end
return def
