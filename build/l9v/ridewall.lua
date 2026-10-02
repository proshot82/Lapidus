-- build/l9v/ridewall.lua файл.lua x,y ... — узкая абляция «с гребня не сдвинуть вбок» на вариантах с замурованной клеткой.
local L = dofile("build/l9v/lib.lua")
local R, SV = L.R, L.SV
local F = dofile("build/l9a/filt.lua")
local noRideMove = function(l, st, ns)
  if ns.dead then return true end
  local _, top = F.columns(l, st)
  for q, p in ipairs(l.pieces) do
    local c, c2 = st.pos[q], ns.pos[q]
    if p.movable and c ~= 0 and not st.fixed[q] and top[c] and c2 ~= 0 then
      local x1 = R.xy(l, c); local x2 = R.xy(l, c2)
      if x1 ~= x2 then return false end
    end
  end
  return true
end
for k = 2, #arg do
  local d = dofile(arg[1])
  local x, y = arg[k]:match("^(%d+),(%d+)$"); x, y = tonumber(x), tonumber(y)
  d.grid[y] = d.grid[y]:sub(1, x - 1) .. "#" .. d.grid[y]:sub(x + 1)
  local lvl = R.compile(d)
  local G = SV.explore(lvl, 3000000, noRideMove)
  print(string.format("замуровано (%d,%d): «с гребня вбок нельзя» → %s", x, y, G.firstWin and ("решаем за " .. G.depth[G.firstWin]) or "НЕРЕШАЕМ"))
  SV.freeGraph(G); io.stdout:flush()
end
