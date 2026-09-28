-- build/l4c/vis_wide.lua — самая широкая ещё честная версия видимого проигрыша кв. 4 (проверка скептика).
-- Всё, что помечает основная (vis_main.lua), плюс то, что видно, лишь поняв «ага»:
--  W1) любая свинченная свободная пара (собранная заранее труба в шахту не пролезает);
--  W2) обе детали свободны, лежат на полу в ряду входа в шахту по одну сторону от неё, пол между ними и входом
--      сплошной, и ниппель ближе к шахте, чем муфта (порядок на полу уже не поменять);
--  W3) деталь лежит на полу в ряду входа, а между ней и входом лежит другая, и обе смотрят «не в том порядке» —
--      частный случай W2; и ниппель в шахте раньше муфты — уже в основной.
local main = dofile("build/l4c/vis_main.lua")
local function wide(lvl, st)
  if main(lvl, st) then return true end
  local qc, qn
  local S
  for q, p in ipairs(lvl.pieces) do
    if p.source then S = p.start end
    if p.what == "coupling" then qc = q elseif p.what == "nipple" then qn = q end
  end
  local T = lvl.nb[lvl.nb[S][1]][1]
  local pc, pn = st.pos[qc], st.pos[qn]
  if st.fixed[qc] or st.fixed[qn] then return false end
  if st.asm[qc] == st.asm[qn] then return true end -- W1
  local W = lvl.W
  local function row(c) return math.floor((c - 1) / W) + 1 end
  local function col(c) return (c - 1) % W + 1 end
  local fixedAt = {}
  for q = 1, #st.pos do if st.pos[q] ~= 0 and st.fixed[q] then fixedAt[st.pos[q]] = true end end
  local function hard(c) return c == 0 or lvl.cell[c] == 1 or fixedAt[c] end
  local function isStatic(c)
    if lvl.cell[c] == 1 then return true end
    for q, p in ipairs(lvl.pieces) do if not p.movable and p.start == c then return true end end
    return false
  end
  if row(pc) == row(T) and row(pn) == row(T) and hard(lvl.nb[pc][3]) and hard(lvl.nb[pn][3]) then
    local xt, xc, xn = col(T), col(pc), col(pn)
    if (xc < xt and xn < xt and xc < xn) or (xc > xt and xn > xt and xc > xn) then
      local step = (xc < xt) and 1 or -1
      local ok = true
      for x = xc + step, xt - step, step do
        local c = (row(T) - 1) * W + x
        if isStatic(c) or lvl.cell[c] == 2 or not hard(lvl.nb[c][3]) then ok = false end
      end
      if ok then return true end -- W2
    end
  end
  return false
end
return wide
