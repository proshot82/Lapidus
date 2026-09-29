-- build/l2c/abl.lua файл.lua X Y1 Y2 — абляции уровня (из def.ablations: обязаны быть нерешаемы) и КОНТРОЛИ (обязаны
-- быть решаемы): контроль показывает, что фильтр/мутация бьёт именно по роли приёма, а не ломает уровень вообще.
-- X, Y1..Y2 — клетки жёлоба под комнатой старта (k9: 8 4 6; k11: 10 4 6); «ниже комнаты» = все клетки на строках ≥ Y1.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local function run(d, filter)
  local lvl = R.compile(d)
  local errs = R.validate(lvl)
  if #errs > 0 then return "ошибка раскладки" end
  local G = SV.explore(lvl, 3000000, filter)
  if not G then return "CAP" end
  local res = G.firstWin and ("РЕШАЕМ, " .. G.depth[G.firstWin] .. " ходов") or ("нерешаем (состояний " .. G.n .. ")")
  SV.freeGraph(G)
  return res
end
print("исходный уровень: " .. run(SV.deepcopy(def)))
for _, ab in ipairs(def.ablations or {}) do
  local d2 = SV.deepcopy(def); d2.ablations = nil
  SV.applyAblation(d2, ab)
  print(string.format("абляция «%s»: %s", ab.name, run(d2, ab.filter)))
end
-- контроли
local C = { tonumber(arg[2] or 8), tonumber(arg[3] or 4), tonumber(arg[4] or 6) }
local function cell(lvl, x, y) return (y - 1) * lvl.W + x end
local function inChute(lvl, c) local x, y = R.xy(lvl, c); return x == C[1] and y >= C[2] and y <= C[3] end
local function flipAll(d) for _, o in ipairs(d.objects) do if o.tag == "hook" then for k, v in pairs(o.ports) do o.ports[k] = (v == "N") and "V" or "N" end end end end
-- падение из комнаты: ход, после которого Лапидус целиком ниже комнаты (все клетки не выше верха жёлоба)
local function below(lvl, s) for _, c in ipairs(s.body) do local _, y = R.xy(lvl, c); if y < C[2] then return false end end return true end
-- «ногами вперёд не падать»: запрещено упасть из комнаты так, что ноги ниже головы
local function noHeelDrop(lvl, st, ns)
  if below(lvl, st) or not below(lvl, ns) then return true end
  local _, yf = R.xy(lvl, ns.body[1]); local _, yh = R.xy(lvl, ns.body[#ns.body])
  return not (yf > yh)
end
-- «головой вперёд не падать» (роль приёма): запрещено упасть из комнаты так, что голова ниже ног
local function noHeadDrop(lvl, st, ns)
  if below(lvl, st) or not below(lvl, ns) then return true end
  local _, yf = R.xy(lvl, ns.body[1]); local _, yh = R.xy(lvl, ns.body[#ns.body])
  return not (yh > yf)
end
local d1 = SV.deepcopy(def); d1.ablations = nil; flipAll(d1)
print("контроль «резьба всех крючьев перевёрнута» (естественный план «ногами вниз» должен стать рабочим): " .. run(d1))
local d2 = SV.deepcopy(def); d2.ablations = nil; flipAll(d2)
print("контроль «резьба перевёрнута + головой вперёд не падать» (с обратной резьбой хватает ног): " .. run(d2, noHeadDrop))
print("роль (сверка с файлом) «головой вперёд не падать» при родной резьбе: " .. run((function() local d = SV.deepcopy(def); d.ablations = nil; return d end)(), noHeadDrop))
local d4 = SV.deepcopy(def); d4.ablations = nil
local lowest
for _, o in ipairs(d4.objects) do if o.tag == "hook" and (not lowest or o.at[2] > lowest.at[2]) then lowest = o end end
for k, v in pairs(lowest.ports) do lowest.ports[k] = (v == "N") and "V" or "N" end
print("мутация «у нижнего крюка резьба В» (голове не за что взяться внизу): " .. run(d4))
local d3 = SV.deepcopy(def); d3.ablations = nil
print("контроль «ногами вниз падать нельзя» (ложный план запрещён — уровень должен остаться решаемым): " .. run(d3, noHeelDrop))
