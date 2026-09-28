-- abl_e.lua — абляции РОЛИ приёмов направления E (фильтры ходов, как в levels/05.lua).
local M = {}
-- «Лапидус не кран»: запрещён любой ход, после которого деталь оказалась выше, чем была (подъём концом).
function M.noCrane(lvl, st, ns)
  for q, p in ipairs(lvl.pieces) do
    if p.movable and st.pos[q] ~= 0 and ns.pos[q] ~= 0 and ns.pos[q] < st.pos[q] - lvl.W + 1 then return false end
  end
  return true
end
-- «Пара не держит деталь над сливом»: запрещено состояние, где незакреплённая деталь висит над сливом
-- (держась за свинченную с ней соседку).
function M.noBridge(lvl, st, ns)
  for q, p in ipairs(lvl.pieces) do
    local c = ns.pos[q]
    if p.movable and c ~= 0 and not ns.fixed[q] then
      local b = lvl.nb[c][3]
      if b ~= 0 and lvl.cell[b] == 2 then return false end
    end
  end
  return true
end
-- «Ниппель не переходит муфту поверху»: запрещено состояние, где свободный ниппель стоит в одном столбце с
-- незакреплённой муфтой выше неё (перенос через муфту — роль приёма «ниппель — за муфту»).
function M.noOver(lvl, st, ns)
  local nq, cq
  for q, p in ipairs(lvl.pieces) do if p.tag == "nip" then nq = q elseif p.tag == "cpl" then cq = q end end
  local n, c = ns.pos[nq], ns.pos[cq]
  if n == 0 or c == 0 or ns.fixed[nq] or ns.fixed[cq] then return true end
  local W = lvl.W
  if (n - 1) % W == (c - 1) % W and n < c then return false end
  return true
end
return M
