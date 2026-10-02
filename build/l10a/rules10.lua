-- build/l10a/rules10.lua — правила видимого проигрыша §7 для кандидатов кв. 10 (мерка новичка, только добавляют к
-- общей линейке tools/vislib.lua; по образцу levels/09.lua): W — у закреплённой детали резьба смотрит в стену или в
-- глухой бок закреплённого; Y — тройник закрыл колодец, а мойка сухая (прибор замурован). Правило T убрано (мёртвое).
local R = require("core.rules")
local RULES = {}
local function occupancy(st)
  local occ = {}
  for q = 1, #st.pos do if st.pos[q] ~= 0 then occ[st.pos[q]] = q end end
  return occ
end
RULES.W = function(lvl, st)
  local occ, P = occupancy(st), lvl.pieces
  for q, p in ipairs(P) do
    local c = st.pos[q]
    if c ~= 0 and st.fixed[q] and p.movable then
      for d = 1, 4 do
        if p.ports[d] then
          local t = lvl.nb[c][d]
          if t == 0 or lvl.cell[t] == R.WALL then return true end
          local r = occ[t]
          if r and st.fixed[r] and not R.match(p.ports[d], P[r].ports[R.OPP[d]]) then return true end
        end
      end
    end
  end
  return false
end
-- Y (скептик build/l10v, 02.10): тройник закреплён на стояке (колодец закрыт навсегда), а мойка сухая — прибор в
-- глухом тоннеле навсегда замурован: ни деталь, ни Лапидус туда больше не попадут. Видимо по мерке новичка.
RULES.Y = function(lvl, st)
  local occ, P = occupancy(st), lvl.pieces
  local w = R.water(lvl, st, occ, true)
  local teeFixed = false
  for q, p in ipairs(P) do
    if p.tag == "tee" and st.pos[q] ~= 0 and st.fixed[q] and w.wet[q] then teeFixed = true end
  end
  if not teeFixed then return false end
  for q, p in ipairs(P) do
    if p.fixture and p.what == "sink" and not w.wet[q] then return true end
  end
  return false
end
local function visibleLoss(lvl, st)
  for _, f in pairs(RULES) do if f(lvl, st) then return true end end
  return false
end
return { RULES = RULES, visibleLoss = visibleLoss }
