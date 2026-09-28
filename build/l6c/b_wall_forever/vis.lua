-- vis.lua — честные «видимые проигрыши» для кандидатов направления B.
-- Смытые детали учитывает check.lua сам. Здесь — только то, что видно с одного взгляда.
local V = {}
local function onBody(st, c) for _, b in ipairs(st.body) do if b == c then return true end end return false end
-- деталь с тегом, начинающимся на "up" (её нужно поднять), лежит не на Лапидусе: на полу, уступе или закреплённом.
-- Поднять можно только то, что лежит на Лапидусе (карточка «Поднимает, но не носит»).
function V.lift(lvl, st)
  for q, p in ipairs(lvl.pieces) do
    if p.tag and p.tag:sub(1, 2) == "up" and st.pos[q] ~= 0 and not st.fixed[q] then
      local b = lvl.nb[st.pos[q]][3]
      if b ~= 0 and lvl.cell[b] == 1 then return true end
      for k = 1, #st.pos do if st.pos[k] == b and st.fixed[k] then return true end end
    end
  end
  return false
end
-- деталь трубы (тег начинается на "p" или "up") закреплена там, откуда её резьба никогда не станет мокрой:
-- на сухом глухом отводе (её сборка не касается ни стояка, ни прибора).
function V.stub(lvl, st)
  local P = lvl.pieces
  for q, p in ipairs(P) do
    if p.movable and p.tag and (p.tag:sub(1, 1) == "p" or p.tag:sub(1, 2) == "up") and st.fixed[q] and st.pos[q] ~= 0 then
      -- обход закреплённой сети по резьбам от детали
      local seen, queue, good = { [q] = true }, { q }, false
      local piece = {}
      for k = 1, #st.pos do if st.pos[k] ~= 0 then piece[st.pos[k]] = k end end
      local h = 1
      while h <= #queue do
        local a = queue[h]; h = h + 1
        if P[a].source or P[a].fixture then good = true end
        for d = 1, 4 do
          local th = P[a].ports[d]
          if th then
            local t = lvl.nb[st.pos[a]][d]
            local r = t ~= 0 and piece[t]
            if r and st.fixed[r] and not seen[r] then
              local th2 = P[r].ports[({3, 4, 1, 2})[d]]
              if th2 and th2 ~= th then seen[r] = true; queue[#queue + 1] = r end
            end
          end
        end
      end
      if not good then return true end
    end
  end
  return false
end
function V.none() return false end
function V.both(lvl, st) return V.lift(lvl, st) or V.stub(lvl, st) end
V.vis = V.both
return V
