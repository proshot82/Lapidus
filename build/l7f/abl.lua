-- build/l7f/abl.lua файл.lua — узкие абляции и контроли из build/l7f/filt.lua: решаем ли уровень при каждом фильтре, длина решения.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local F = dofile("build/l7f/filt.lua")
local def = dofile(arg[1])
local lvl = R.compile(def)
local tests = {
  { "струя не поднимает тело Лапидуса целиком (узко, по трассе)", F.lapLifted },
  { "ШИРОКО (для сравнения): тело не бывает в столбе неприкрученным", F.noLapRide },
  { "деталь в столбе не вдавить сверху (над деталью в столбе нет тела)", F.noPushDown },
  { "фонтан не держит деталь на весу (детали нет в столбе и над верхушкой)", F.noHover },
  { "КОНТРОЛЬ: пара ниппель+угольник не свинчивается на лету", F.noPair },
  { "КОНТРОЛЬ: угольник не бывает на нижнем полу", F.elbowStaysUp },
  { "КОНТРОЛЬ: ниппель не бывает на нижнем полу", F.nipStaysUp },
}
for _, t in ipairs(tests) do
  local G = SV.explore(lvl, 3000000, t[2])
  if G and G.firstWin then print(string.format("РЕШАЕМ за %d (состояний %d): %s", G.depth[G.firstWin], G.n, t[1]))
  else print(string.format("нерешаем (состояний %d): %s", G and G.n or -1, t[1])) end
  if G then SV.freeGraph(G) end
end
