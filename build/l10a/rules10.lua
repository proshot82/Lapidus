-- build/l10a/rules10.lua — правила видимого проигрыша §7 для кандидатов кв. 10 (мерка новичка, только добавляют к
-- общей линейке tools/vislib.lua; по образцу levels/09.lua): W — у закреплённой детали резьба смотрит в стену или в
-- глухой бок закреплённого; T — порт сети занят навсегда закреплённой деталью без ответной резьбы.
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
RULES.T = function(lvl, st)
  local occ, P = occupancy(st), lvl.pieces
  for q, p in ipairs(P) do
    local c = st.pos[q]
    if c ~= 0 and not p.movable then
      for d = 1, 4 do
        if p.ports[d] then
          local t = lvl.nb[c][d]
          local r = t ~= 0 and occ[t] or nil
          if r and st.fixed[r] and P[r].movable and not R.match(p.ports[d], P[r].ports[R.OPP[d]]) then return true end
        end
      end
    end
  end
  return false
end
local function visibleLoss(lvl, st)
  for _, f in pairs(RULES) do if f(lvl, st) then return true end end
  return false
end
return { RULES = RULES, visibleLoss = visibleLoss }
