-- фильтры абляций роли для кв. 6
local R = require("core.rules")
local F = {}
local function rowOf(lvl, c) return math.floor((c - 1) / lvl.W) end
-- «деталь не падает»: ни одна подвижная деталь не может оказаться ниже, чем была (если её не смыло)
function F.noDrop(lvl, st, ns)
  for q = 1, #st.pos do
    local a, b = st.pos[q], ns.pos[q]
    if a ~= 0 and b ~= 0 and lvl.pieces[q].movable and rowOf(lvl, b) > rowOf(lvl, a) then return false end
  end
  return true
end
-- «кран запрещён»: ни одна деталь не может оказаться выше, чем была
function F.noLift(lvl, st, ns)
  for q = 1, #st.pos do
    local a, b = st.pos[q], ns.pos[q]
    if a ~= 0 and b ~= 0 and rowOf(lvl, b) < rowOf(lvl, a) then return false end
  end
  return true
end
-- «ноги не поднимают»: запрещено поднимать деталь ходом ног
function F.noHeelLift(lvl, st, ns)
  for q = 1, #st.pos do
    local a, b = st.pos[q], ns.pos[q]
    if a ~= 0 and b ~= 0 and rowOf(lvl, b) < rowOf(lvl, a) then
      -- кто двигался: ноги, если сменилась клетка ног и голова осталась (или скольжение)
      if ns.body[1] ~= st.body[1] and ns.body[#ns.body] == st.body[#st.body] then return false end
    end
  end
  return true
end
-- «без якоря»: нельзя поднимать деталь, если ни один конец не прикручен
function F.liftOnlyAnchored(lvl, st, ns)
  for q = 1, #st.pos do
    local a, b = st.pos[q], ns.pos[q]
    if a ~= 0 and b ~= 0 and rowOf(lvl, b) < rowOf(lvl, a) then
      local piece = R.occupancy(st)
      if not (R.endScrew(lvl, st, piece, "head") or R.endScrew(lvl, st, piece, "heel")) then return true end
    end
  end
  return true
end
return F
