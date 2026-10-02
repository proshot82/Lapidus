-- verify_vis_min.lua — минимальная правка проверяющего: vis_m.lua (как у автора) + только бесспорное:
--  6) деталь прикручена намертво не там, где ей место (ниппель — не в гнезде колонки, муфта — не в гнезде пола);
--  7) две подвижные детали свинтились между собой навсегда.
local base = dofile("build/l6c/c_stub_ladder/vis_m.lua")
return function(lvl, st)
  if base(lvl, st) then return true end
  local def = lvl.def
  local okFixed = {}
  for q, p in ipairs(lvl.pieces) do
    if (p.source or p.kind == "stub") and p.ports[1] then okFixed[lvl.nb[p.start][1]] = "slide" end
    if p.fixture then for d = 1, 4 do if p.ports[d] then okFixed[lvl.nb[p.start][d]] = "lift" end end end
  end
  local seen = {}
  for q, p in ipairs(lvl.pieces) do
    if p.movable and st.pos[q] ~= 0 then
      if st.fixed[q] then
        local want = (def.lift and def.lift[p.tag]) and "lift" or "slide"
        if okFixed[st.pos[q]] ~= want then return true end
      else
        local a = st.asm[q]
        if seen[a] then return true end
        seen[a] = true
      end
    end
  end
  return false
end
