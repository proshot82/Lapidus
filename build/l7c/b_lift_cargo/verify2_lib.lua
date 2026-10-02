-- verify2_lib.lua — помощники второй проверки скептика (кв. 7, кандидат p2b, 28.09.2026).
-- Решений, кадров и порядка ходов не печатает. Используется verify2_*.lua.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local M = { R = R, SV = SV }

-- номера деталей по тегам, столб фонтана (x стояка), строка стояка
function M.keys(lvl)
  local k = {}
  for q, p in ipairs(lvl.pieces) do
    if p.tag then k[p.tag] = q end
    if p.source then k.src = q end
    if p.fixture then k.fix = q end
  end
  local sx, sy = R.xy(lvl, lvl.pieces[k.src].start)
  k.sx, k.sy = sx, sy
  return k
end

function M.graph(def, filter)
  local lvl = R.compile(def)
  local G = SV.explore(lvl, 3000000, filter)
  local good = G and G.firstWin and SV.goodSet(G) or nil
  return lvl, G, good
end

function M.path(G)
  local path, x = {}, G.firstWin
  while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
  table.insert(path, 1, 1)
  return path
end

-- смыта ли нужная деталь (в этом уровне слива нет, но формула общая, как в check.lua)
function M.washed(lvl, st)
  for q, p in ipairs(lvl.pieces) do if p.movable and st.pos[q] == 0 then return true end end
  return false
end

-- конфигурация деталей строкой (без Лапидуса)
function M.cfg(lvl, st)
  local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then
    if st.pos[q] == 0 then t[#t + 1] = p.tag .. "(смыт)" else
      local x, y = R.xy(lvl, st.pos[q]); t[#t + 1] = string.format("%s(%d,%d)%s", p.tag, x, y, st.fixed[q] and "F" or "") end
  end end
  return table.concat(t, " ")
end

-- две детали в одной подвижной сборке (или обе закреплены и свинчены по резьбе друг с другом)
function M.joined(lvl, st, a, b)
  if st.pos[a] == 0 or st.pos[b] == 0 then return false end
  if not st.fixed[a] and not st.fixed[b] then return st.asm[a] == st.asm[b] end
  if st.fixed[a] and st.fixed[b] then
    local d = R.dirBetween(lvl, st.pos[a], st.pos[b])
    if not d then return false end
    local pa, pb = lvl.pieces[a].ports[d], lvl.pieces[b].ports[R.OPP[d]]
    return pa ~= nil and pb ~= nil and R.match(pa, pb)
  end
  return false
end

-- деталь upper свинчена прямо на lower сверху (соседние клетки, резьбы лицом к лицу, одна сборка или обе закреплены)
function M.screwedOn(lvl, st, upper, lower)
  local cu, cl = st.pos[upper], st.pos[lower]
  if cu == 0 or cl == 0 or lvl.nb[cl][R.UP] ~= cu then return false end
  local pu, pl = lvl.pieces[upper].ports[R.DOWN], lvl.pieces[lower].ports[R.UP]
  if not (pu and pl and R.match(pu, pl)) then return false end
  if st.fixed[upper] and st.fixed[lower] then return true end
  return (not st.fixed[upper]) and (not st.fixed[lower]) and st.asm[upper] == st.asm[lower]
end

-- сторона Лапидуса относительно столба: L (весь левее), R (весь правее), C (задевает столб)
function M.lapSide(lvl, st, sx)
  local l, r = false, false
  for _, c in ipairs(st.body) do
    local x = R.xy(lvl, c)
    if x < sx then l = true elseif x > sx then r = true else return "C" end
  end
  if l and not r then return "L" elseif r and not l then return "R" end
  return "C"
end

return M
