-- Видимый проигрыш уровня (дополняет общую линейку tools/vislib.lua; мерка НОВИЧКА — только то, что видно без знания
-- финальной сборки): закреплённая деталь смотрит открытой резьбой в стену или в глухой бок / такую же резьбу
-- закреплённого — эта течь навсегда (как правило 1 в levels/04.lua).
local OPP = { 3, 4, 1, 2 }
local function visibleLoss(lvl, st)
  local occ = {}
  for q, p in ipairs(lvl.pieces) do
    if st.pos[q] ~= 0 then occ[st.pos[q]] = q elseif p.movable then return true end
  end
  for q, p in ipairs(lvl.pieces) do
    if p.movable and st.fixed[q] then
      for d = 1, 4 do
        local th = p.ports[d]
        if th then
          local t = lvl.nb[st.pos[q]][d]
          if t == 0 or lvl.cell[t] == 1 then return true end
          local r = occ[t]
          if r and st.fixed[r] then
            local th2 = lvl.pieces[r].ports[OPP[d]]
            if th2 == nil or th2 == th then return true end
          end
        end
      end
    end
  end
  return false
end

local function tagOf(lvl, tag) for q, p in ipairs(lvl.pieces) do if p.tag == tag then return q end end end
local function rowOf(lvl, c) return math.floor((c - 1) / lvl.W) + 1 end

-- Абляция РОЛИ «ступенька»: стоя на незакреплённой заглушке, Лапидус не поднимается выше, чем достаёт с пола
-- (ни одно звено не выше клетки «заглушка − Lmax»). Ходить по ней, толкать её, лежать на ней — можно.
local function noStep(lvl, st, ns)
  local pq = tagOf(lvl, "plug")
  local c = ns.pos[pq]
  if c == 0 or ns.fixed[pq] then return true end
  local above = lvl.nb[c][1]
  local on = false
  for _, b in ipairs(ns.body) do if b == above then on = true end end
  if not on then return true end
  local pr = rowOf(lvl, c)
  for _, b in ipairs(ns.body) do if rowOf(lvl, b) <= pr - lvl.Lmax then return false end end
  return true
end
