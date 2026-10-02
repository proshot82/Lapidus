-- vis_wide.lua — ЗАВЕДОМО ШИРОКИЙ видимый проигрыш, только для проверки чувствительности (не честный: включает «ага»).
-- vis_e.lua + ниппель вкручен не в пару у стояка + ниппель на полу ближе к стояку, чем свободная муфта
-- + пара, свинченная ниппелем к стояку.
local base = dofile("build/l6c/e_orientation/vis_e.lua")
return function(lvl, st)
  if base(lvl, st) then return true end
  local nq, cq, sq
  for q, p in ipairs(lvl.pieces) do if p.tag == "nip" then nq = q elseif p.tag == "cpl" then cq = q elseif p.source then sq = q end end
  local W = lvl.W
  local n, c = st.pos[nq], st.pos[cq]
  if n == 0 or c == 0 then return false end
  local sx = (lvl.pieces[sq].start - 1) % W + 1
  local nx, cx = (n - 1) % W + 1, (c - 1) % W + 1
  local ny, cy = math.floor((n - 1) / W) + 1, math.floor((c - 1) / W) + 1
  local toward = (sx > nx) and 1 or -1
  if st.fixed[nq] and not st.fixed[cq] then return true end
  if st.fixed[nq] and st.fixed[cq] and st.asm[nq] ~= st.asm[cq] then end
  if not st.fixed[nq] and not st.fixed[cq] and ny == cy and (nx - cx) * toward > 0 then
    local b = lvl.nb[n][3]
    if b ~= 0 and (lvl.cell[b] == 1 or st.asm[nq] == st.asm[cq]) then return true end
    if st.asm[nq] == st.asm[cq] then return true end
  end
  return false
end
