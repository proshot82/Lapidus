-- build/l8j/vis.lua — честный видимый проигрыш кандидатов кв. 8 (добавка к общей линейке tools/vislib.lua).
-- 1) как build/l6j/vis.lua: закреплённая деталь смотрит открытой резьбой в стену, в глухой бок закреплённого
--    или в такую же резьбу — шов, который никогда не закрыть;
-- 3) деталь, которую можно поднять только на Лапидусе (def.mustLift — список тегов), лежит прямо на стене или на
--    закреплённом: снизу к ней не подлезть и подставку не выбить — «лежит там, где её нечем поднять» (DESIGN §7).
-- 2) открытая резьба закреплённой детали упирается в фаянс, который уже никак не сдвинуть (ни толкнуть вбок —
--    некуда встать или некуда ехать, ни поднять снизу) — выход навсегда занят мылом (мерка новичка, DESIGN §7).
local OPP = { 3, 4, 1, 2 }
return function(lvl, st)
  local occ = {}
  for q = 1, #st.pos do if st.pos[q] ~= 0 then occ[st.pos[q]] = q end end
  local body = {}
  for _, c in ipairs(st.body) do body[c] = true end
  local function solid(c)
    if c == 0 or lvl.cell[c] == 1 then return true end
    local r = occ[c]
    return r ~= nil and st.fixed[r]
  end
  local function frozenSoap(c)
    -- вбок: с одной стороны можно встать концом, с другой — свободно (или слив)
    for _, d in ipairs({ 2, 4 }) do
      local p, t = lvl.nb[c][OPP[d]], lvl.nb[c][d]
      if not solid(p) and lvl.cell[p] ~= 2 and not solid(t) then return false end
    end
    -- вверх: снизу не стена и не закреплённое, сверху не стена и не закреплённое
    local b, u = lvl.nb[c][3], lvl.nb[c][1]
    if not solid(b) and lvl.cell[b] ~= 2 and not solid(u) then return false end
    return true
  end
  local ml = lvl.def and lvl.def.mustLift
  if ml then
    for q, p in ipairs(lvl.pieces) do
      if st.pos[q] ~= 0 and not st.fixed[q] then
        for _, tg in ipairs(ml) do
          if p.tag == tg then
            local b = lvl.nb[st.pos[q]][3]
            if solid(b) then return true end
            local r = occ[b]
            if r and lvl.pieces[r].porcelain and frozenSoap(b) then return true end
          end
        end
      end
    end
  end
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
          elseif r and lvl.pieces[r].porcelain and frozenSoap(t) then
            return true
          end
        end
      end
    end
  end
  return false
end
