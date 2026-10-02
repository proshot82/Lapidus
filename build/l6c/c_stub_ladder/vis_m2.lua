-- vis_m2.lua — СТРОГИЙ (широкий) видимый проигрыш для семейства M, для проверки запаса. Всё из vis_m.lua, плюс:
--  4) незакреплённая муфта в нижнем ярусе, у которой клетка «сзади» (откуда её толкать к ближайшему свободному гнезду)
--     занята закреплённым — считаем, что «стену» из прикрученной детали игрок видит так же, как настоящую;
--  5) между незакреплённой муфтой и всеми свободными гнёздами в ряду стоит закреплённое — муфте не пройти.
local base = dofile("build/l6c/c_stub_ladder/vis_m.lua")
return function(lvl, st)
  if base(lvl, st) then return true end
  local def = lvl.def
  local W = lvl.W
  local fixedAt = {}
  for k = 1, #st.pos do if st.pos[k] ~= 0 and st.fixed[k] then fixedAt[st.pos[k]] = k end end
  local function row(c) return math.floor((c - 1) / W) + 1 end
  local function col(c) return (c - 1) % W + 1 end
  local sockets = {}
  for q, p in ipairs(lvl.pieces) do
    if (p.source or p.kind == "stub") and p.ports[1] then sockets[#sockets + 1] = lvl.nb[p.start][1] end
  end
  for q, p in ipairs(lvl.pieces) do
    if p.tag and def.slide and def.slide[p.tag] and st.pos[q] ~= 0 and not st.fixed[q] then
      local c = st.pos[q]
      local reachable = false
      for _, s in ipairs(sockets) do
        if not fixedAt[s] and row(s) == row(c) then
          local dir = (col(s) < col(c)) and -1 or 1
          local back = c - dir
          local okBack = (lvl.cell[back] == 0) and not fixedAt[back]
          local okPath = true
          local x = c
          while x ~= s do x = x + dir; if lvl.cell[x] ~= 0 or fixedAt[x] then okPath = false end end
          if col(s) == col(c) then okBack = true end
          if okBack and okPath then reachable = true end
        end
      end
      if not reachable then return true end
    end
  end
  return false
end
