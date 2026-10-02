-- from.lua файл.lua "ходы" — сыграть ходы (формат pl.lua) и сказать, решаем ли уровень из полученного состояния,
-- и видим ли проигрыш новичку/знатоку. Печатает только вердикт (ходы — во входе, в файлы не переносить).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local st = R.newState(lvl)
local DIR = { ["^"] = 1, [">"] = 2, ["v"] = 3, ["<"] = 4 }
for tok in (arg[2] or ""):gmatch("%S+") do
  local w, d = tok:sub(1, 1), tok:sub(2, 2)
  local ns = R.move(lvl, st, w == "H" and "head" or "heel", DIR[d])
  assert(ns, "ход невозможен: " .. tok)
  st = ns
end
local orig = R.newState
R.newState = function() return R.clone(st) end
local G = SV.explore(lvl, 3000000)
R.newState = orig
print(string.format("после %d ходов: %s (состояний %d%s)", select(2, (arg[2] or ""):gsub("%S+", "")), G.firstWin and "РЕШАЕМ" or "тупик",
  G.n, G.firstWin and (", до победы " .. G.depth[G.firstWin]) or ""))
SV.freeGraph(G)
