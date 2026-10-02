-- build/l4c/vis_v3.lua — НЕ честная версия, только оценка запаса (как v3 у скептика r9, кв. 6):
-- широкая (vis_wide.lua) + «к клетке, откуда деталь толкают к шахте (слева от неё), Лапидусу уже не пройти»:
-- обход по пустым клеткам от этой клетки, не проходя через саму деталь и вторую деталь, не находит ни одной клетки Лапидуса.
local wide = dofile("build/l4c/vis_wide.lua")
return function(lvl, st)
  if wide(lvl, st) then return true end
  local occ = {}
  for q = 1, #st.pos do if st.pos[q] ~= 0 then occ[st.pos[q]] = q end end
  local lap = {}
  for _, c in ipairs(st.body) do lap[c] = true end
  local function open(c) return c ~= 0 and lvl.cell[c] == 0 end
  for q, p in ipairs(lvl.pieces) do
    local c = st.pos[q]
    if p.movable and c ~= 0 and not st.fixed[q] and st.asm[q] == q then
      local b = lvl.nb[c][3]
      local hard = b == 0 or lvl.cell[b] == 1 or (occ[b] and st.fixed[occ[b]])
      local left = lvl.nb[c][4]
      if hard and open(left) and not occ[left] then
        local seen, qu, h, found = { [left] = true }, { left }, 1, lap[left] or false
        while h <= #qu and not found do
          local u = qu[h]; h = h + 1
          for d = 1, 4 do
            local v = lvl.nb[u][d]
            if v ~= 0 and not seen[v] and v ~= c and open(v) and not (occ[v] and not lap[v]) then
              seen[v] = true; qu[#qu + 1] = v
              if lap[v] then found = true end
            end
          end
        end
        if not found then return true end
      end
    end
  end
  return false
end
