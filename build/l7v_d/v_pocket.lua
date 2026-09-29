-- build/l7v_d/v_pocket.lua — разметка новичка только с правилом A (карман слева), без B.
local def = dofile("build/l7c/d_tee_lift/L7D.lua")
local orig = def.visibleLoss
local function idx(lvl, x, y) return (y - 1) * lvl.W + x end
def.visibleLoss = function(lvl, st)
  if orig(lvl, st) then return true end
  local pocket = { [idx(lvl, 2, 6)] = true, [idx(lvl, 3, 6)] = true, [idx(lvl, 3, 5)] = true }
  for q, p in ipairs(lvl.pieces) do
    if p.movable and st.pos[q] ~= 0 and not st.fixed[q] and pocket[st.pos[q]] then return true end
  end
  return false
end
return def
