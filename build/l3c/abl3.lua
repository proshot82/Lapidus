-- build/l3c/abl3.lua — фильтры абляций роли для кв. 3 (для черновиков; в файл уровня вписываются целиком).
local M = {}
local function soapsOf(lvl, s)
  local t = {}
  for q, p in ipairs(lvl.pieces) do if p.porcelain and s.pos[q] ~= 0 then t[#t + 1] = q end end
  return t
end
local function bodySet(s) local b = {} for _, c in ipairs(s.body) do b[c] = true end return b end
-- «Подставку не выбить»: нельзя смыть мыло, пока на нём лежит другое мыло.
function M.noKick(lvl, st, ns)
  for q, p in ipairs(lvl.pieces) do
    if p.porcelain and st.pos[q] ~= 0 and ns.pos[q] == 0 then
      local up = lvl.nb[st.pos[q]][1]
      for r, pr in ipairs(lvl.pieces) do if r ~= q and pr.porcelain and st.pos[r] == up then return false end end
    end
  end
  return true
end
-- «Мыло на мыло не ляжет»: запрещено состояние, где мыло стоит прямо на другом мыле.
function M.noStack(lvl, st, ns)
  local at = {}
  for q, p in ipairs(lvl.pieces) do if p.porcelain and ns.pos[q] ~= 0 then at[ns.pos[q]] = true end end
  for c in pairs(at) do if at[lvl.nb[c][3]] then return false end end
  return true
end
-- «Мост запрещён»: запрещено состояние, где мыло лежит на Лапидусе прямо над сливом.
function M.noBridge(lvl, st, ns)
  local b = bodySet(ns)
  for q, p in ipairs(lvl.pieces) do
    local c = ns.pos[q]
    if p.porcelain and c ~= 0 then
      local d = lvl.nb[c][3]
      if b[d] and lvl.cell[lvl.nb[d][3]] == 2 then return false end
    end
  end
  return true
end
-- контроль «подъёмник запрещён»: ногами нельзя толкнуть мыло вверх.
function M.noLift(lvl, st, ns)
  for q, p in ipairs(lvl.pieces) do
    if p.porcelain and st.pos[q] ~= 0 and ns.pos[q] ~= 0 and ns.pos[q] == lvl.nb[st.pos[q]][1] then return false end
  end
  return true
end
-- контроль «мыло не толкать влево».
function M.noLeft(lvl, st, ns)
  for q, p in ipairs(lvl.pieces) do
    if p.porcelain and st.pos[q] ~= 0 and ns.pos[q] ~= 0 and ns.pos[q] == lvl.nb[st.pos[q]][4] then return false end
  end
  return true
end
return M
