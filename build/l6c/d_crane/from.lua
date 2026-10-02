-- from.lua файл.lua "ходы" — проиграть ходы (H/F + U/R/D/L) и решить оттуда BFS'ом; печатает кадры (только вывод инструмента).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local def = dofile(arg[1])
local lvl = R.compile(def)
local st = R.newState(lvl)
local D = { U = 1, R = 2, D = 3, L = 4 }
for mv in (arg[2] or ""):gmatch("%S+") do
  local ns, why = R.move(lvl, st, mv:sub(1,1) == "H" and "head" or "heel", D[mv:sub(2,2)])
  if not ns then print("ход невозможен: " .. mv .. " " .. tostring(why)) return end
  st = ns
end
local seen, q, par, pm = { [R.key(st)] = true }, { st }, {}, {}
local h, found = 1, nil
while h <= #q do
  local s = q[h]; h = h + 1
  if R.isWin(lvl, s) then found = s break end
  for m = 1, 8 do
    local mv = R.MOVES[m]
    local ns = R.move(lvl, s, mv.which, mv.dir)
    if ns and not ns.dead then
      local k = R.key(ns)
      if not seen[k] then seen[k] = true; par[ns] = s; pm[ns] = m; q[#q+1] = ns end
    end
  end
end
print("достижимо состояний", #q, found and "РЕШАЕМО" or "ТУПИК")
if found and arg[3] == "show" then
  local path, x = {}, found
  while par[x] do table.insert(path, 1, pm[x]); x = par[x] end
  local t = {}
  for _, m in ipairs(path) do local mv = R.MOVES[m]; t[#t+1] = (mv.which == "head" and "H" or "F") .. ({"U","R","D","L"})[mv.dir] end
  print(table.concat(t, " "))
end
