-- build/l9v/rules.lua файл.lua — какие правила общей линейки срабатывают (счётчики tools/vislib.lua), есть ли у файла
-- свой visibleLoss, может ли заглушка/деталь оказаться на входе прибора. Только метрики.
local L = dofile("build/l9v/lib.lua")
local S = L.load(arg[1])
local R = L.R
print("def.visibleLoss в файле: " .. (S.def.visibleLoss and "есть" or "НЕТ — только общая линейка"))
local c = S.VL.counts
print(string.format("линейка: видимых по «смыто» %d, по «никогда не сдвинется/карман» %d, по правилу уровня %d; «всеведение» (деталь уже не попадёт на место) дополнительно %d",
  c.washed, c.frozen, c.levelRule, c.goal))
local liveMarked = 0
for i = 1, S.n do if S.flag[i] ~= 2 and S:live(i) and (S.VL.newbie[i] or S.VL.expert[i]) then liveMarked = liveMarked + 1 end end
print("живых, помеченных новичком или знатоком: " .. liveMarked)
-- деталь на входе прибора: подвижная деталь в клетке перед резьбой прибора
local lvl = S.lvl
local fixIn = {}
for q, p in ipairs(lvl.pieces) do if p.fixture then for d = 1, 4 do if p.ports[d] then fixIn[lvl.nb[p.start][d]] = p.what end end end end
local hit = {}
for i = 1, S.n do if S.flag[i] ~= 2 then local s = S:st(i)
  for q, p in ipairs(lvl.pieces) do if p.movable and s.pos[q] ~= 0 and fixIn[s.pos[q]] then
    local k = p.tag .. " у входа " .. fixIn[s.pos[q]] .. (s.fixed[q] and " (закреплена)" or " (свободна)")
    hit[k] = (hit[k] or 0) + 1 end end end end
local any = false
for k, v in pairs(hit) do print("  " .. k .. ": состояний " .. v); any = true end
if not any then print("  ни одна подвижная деталь ни в одном состоянии не стоит у входа прибора") end
S:free()
