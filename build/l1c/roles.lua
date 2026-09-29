-- build/l1c/roles.lua файл.lua — абляции РОЛИ и контроли для кандидатов семейства «разворот через карман у крюка».
-- Геометрию берёт из файла: крюк — объект stub; карман — клетки под развилкой J (две открытые клетки с дном);
-- шахта Y — вертикаль под концом коридора; тупик R — клетки, где бывает только класс O (из an.lua не берём:
-- считаем здесь же). Печатает «нерешаем/РЕШАЕМ» и число ходов; решений не печатает.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local function deepcopy(t) return SV.deepcopy(t) end
local lvl = R.compile(def)
local hookQ
for q, p in ipairs(lvl.pieces) do if p.kind == "stub" then hookQ = q end end
local hx, hy = R.xy(lvl, lvl.pieces[hookQ].start)

local function solveWith(d, filter)
  local ok, l2 = pcall(R.compile, d)
  if not ok or #R.validate(l2) > 0 then return "нерешаем (раскладка)" end
  local G = SV.explore(l2, 3000000, filter)
  if not G then return "CAP" end
  local res = G.firstWin and ("РЕШАЕМ, ходов " .. G.depth[G.firstWin]) or "нерешаем"
  SV.freeGraph(G)
  return res
end
local function setCell(d, x, y, ch)
  local r = d.grid[y]
  d.grid[y] = r:sub(1, x - 1) .. ch .. r:sub(x + 1)
end

-- клетки кармана: открытые клетки под коридором, у которых снизу стена, а сверху — развилка без опоры
local pocket = {}
for x = 2, lvl.W - 1 do
  local c2, c3, c4, c5 = R.idx(lvl, x, 2), R.idx(lvl, x, 3), R.idx(lvl, x, 4), R.idx(lvl, x, 5)
  if lvl.cell[c2] == 0 and lvl.cell[c3] == 0 and lvl.cell[c4] == 0 and lvl.cell[c5] == 1 then pocket[#pocket + 1] = { x, 3 }; pocket[#pocket + 1] = { x, 4 } end
end

local out = {}
-- 1) крюк замурован
do
  local d = deepcopy(def); d.ablations = nil
  local keep = {}
  for _, o in ipairs(d.objects) do if o.kind ~= "stub" then keep[#keep + 1] = o end end
  d.objects = keep
  setCell(d, hx, hy, "#")
  out[#out + 1] = { "роль: крюк замурован (стена на его месте)", solveWith(d) }
end
-- 2) крюк без крепления
do
  local function noHook(l, st, ns)
    local piece = R.occupancy(ns)
    for _, which in ipairs({ "head", "heel" }) do
      local q = R.endScrew(l, ns, piece, which)
      if q and l.pieces[q].kind == "stub" then return false end
    end
    return true
  end
  local d = deepcopy(def); d.ablations = nil
  out[#out + 1] = { "роль: крюк без крепления (конец к нему не прикручивается)", solveWith(d, noHook) }
end
-- 3) карман засыпан
if #pocket > 0 then
  local d = deepcopy(def); d.ablations = nil
  for _, c in ipairs(pocket) do setCell(d, c[1], c[2], "#") end
  out[#out + 1] = { "роль: карман засыпан", solveWith(d) }
end
-- 4) контроль: голова не может висеть на крюке (крюк держит только ноги — как и по резьбе), то есть фильтр,
--    запрещающий ГОЛОВЕ касаться клетки крюка-соседа... для V-крюка это пустое ограничение: должен быть РЕШАЕМ
do
  local d = deepcopy(def); d.ablations = nil
  local anchor = R.idx(lvl, hx + (lvl.pieces[hookQ].ports[2] and 1 or (lvl.pieces[hookQ].ports[4] and -1 or 0)), hy)
  local function noHeadAtAnchor(l, st, ns) return ns.body[#ns.body] ~= anchor end
  out[#out + 1] = { "контроль: голова не заходит к крюку", solveWith(d, noHeadAtAnchor) }
end
-- 5) контроль: запрещено спускаться в шахту ногами вперёд (сама ошибка подсказки №1) — решаемость не должна пострадать
do
  local d = deepcopy(def); d.ablations = nil
  local function noHeelFirst(l, st, ns)
    local b = ns.body
    local _, hyy = R.xy(l, b[#b])
    local _, fyy = R.xy(l, b[1])
    local allLow = true
    for _, c in ipairs(b) do local _, y = R.xy(l, c); if y <= 2 then allLow = false end end
    if allLow and fyy > hyy then return false end
    return true
  end
  out[#out + 1] = { "контроль: запрещено оказаться целиком в шахте ногами ниже головы", solveWith(d, noHeelFirst) }
end
for _, o in ipairs(out) do print(string.format("%-78s %s", o[1], o[2])) end
