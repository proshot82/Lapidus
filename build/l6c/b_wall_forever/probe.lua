-- probe.lua файл.lua "ходы" — после каждого хода: живое / скрытый тупик / видимый / смыло (только вывод инструмента)
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local function lost(s)
  for q, p in ipairs(lvl.pieces) do if p.movable and s.pos[q] == 0 then return true end end
  return def.visibleLoss and def.visibleLoss(lvl, s) or false
end
local st = R.newState(lvl)
local function cls(s)
  local id = G.index[R.key(s)]
  if not id then return "?" end
  if G.flag[id] == 1 then return "WIN" end
  if G.flag[id] == 2 then return "смыло" end
  if good[id] == 1 then return lost(s) and "живое(ЛОЖНОВИД)" or "живое" end
  return lost(s) and "видимый" or "СКРЫТЫЙ"
end
print("старт: " .. cls(st) .. (G.firstWin and (" | кратчайшее " .. G.depth[G.firstWin]) or " | НЕРЕШАЕМ"))
local k = 0
for tok in (arg[2] or ""):gmatch("%S+") do
  local w, d = tok:match("^(%a+):(%a+)$")
  local which = (w == "H" or w == "head") and "head" or "heel"
  local dir = ({ up = 1, right = 2, down = 3, left = 4, u = 1, r = 2, d = 3, l = 4 })[d]
  local ns, why = R.move(lvl, st, which, dir)
  k = k + 1
  if not ns then print(k .. " " .. tok .. ": нельзя (" .. tostring(why) .. ")") else st = ns; print(k .. " " .. tok .. ": " .. cls(st)) end
end
SV.freeGraph(G); require("ffi").C.free(good)
