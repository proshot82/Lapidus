-- verify_vis.lua — более широкие версии «видимого проигрыша» для проверки r9 (скептик).
-- level: 1 = vis_e + свинченная пара, у которой ОБА свободных конца той же резьбы, что их цель
--            (к стояку смотрит Н, как у стояка; к колонке — В, как у колонки): сборку не повернуть, это видно по резьбе.
--        2 = 1 + обе детали свободны и лежат на твёрдом (не на Лапидусе) в одном ряду, ниппель ближе к стояку:
--            поднять ни одну нельзя, порядок навсегда, при встрече свинтятся «не той стороной».
--        3 = 2 + муфта на полу так близко к стене сзади, что за ней нет двух клеток (ниппель + толкающий конец)
--            + ниппель вкручен в колонку (ложный план) — НЕ честно, только оценка запаса.
local base = dofile("build/l6c/e_orientation/vis_e.lua")
return function(level)
  return function(lvl, st)
    if base(lvl, st) then return true end
    local W = lvl.W
    local nq, cq, sx
    for q, p in ipairs(lvl.pieces) do
      if p.tag == "nip" then nq = q elseif p.tag == "cpl" then cq = q elseif p.source then sx = (p.start - 1) % W + 1 end
    end
    local n, c = st.pos[nq], st.pos[cq]
    if n == 0 or c == 0 then return false end
    local nx, cx = (n - 1) % W + 1, (c - 1) % W + 1
    local ny, cy = math.floor((n - 1) / W) + 1, math.floor((c - 1) / W) + 1
    local toward = (sx > cx) and 1 or -1
    local freeN, freeC = not st.fixed[nq], not st.fixed[cq]
    -- 1: пара «не той стороной»
    if freeN and freeC and st.asm[nq] == st.asm[cq] and (nx - cx) * toward > 0 then return true end
    if level < 2 then return false end
    local function onHard(p)
      local b = lvl.nb[p][3]
      return b == 0 or lvl.cell[b] == 1
    end
    if freeN and freeC and st.asm[nq] ~= st.asm[cq] and ny == cy and onHard(n) and onHard(c) and (nx - cx) * toward > 0 then return true end
    if level < 3 then return false end
    if st.fixed[nq] and not st.fixed[cq] then return true end
    if freeC and onHard(c) then
      local b1 = c - toward; local b2 = c - 2 * toward
      if lvl.cell[b1] == 1 or lvl.cell[b2] == 1 then return true end
    end
    return false
  end
end
