-- build/l8v/ctl.lua файл.lua — скептик кв. 8: абляции и контроли уровня с фильтрами ходов (def.ablations, def.controls):
-- для каждого — решаем ли, минимум ходов, число состояний. Абляция обязана быть нерешаемой, контроль — решаемым
-- (иначе фильтр абляции шире, чем заявленный приём). Решения не печатаются.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local function run(ab, kind)
  local d2 = SV.deepcopy(def); d2.ablations = nil; d2.controls = nil
  SV.applyAblation(d2, ab)
  local ok, lvl2 = pcall(R.compile, d2)
  if not ok or #R.validate(lvl2) > 0 then print(string.format("%s «%s»: не компилируется → нерешаем", kind, ab.name)) return end
  local G = SV.explore(lvl2, 3000000, ab.filter)
  if not G then print(string.format("%s «%s»: CAP", kind, ab.name)) return end
  print(string.format("%s «%s»: %s | состояний %d%s", kind, ab.name, G.firstWin and "РЕШАЕМ" or "нерешаем", G.n,
    G.firstWin and (" | ходов " .. G.depth[G.firstWin]) or ""))
  SV.freeGraph(G)
end
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
print(string.format("база: %s | состояний %d%s", G.firstWin and "РЕШАЕМ" or "нерешаем", G.n, G.firstWin and (" | ходов " .. G.depth[G.firstWin]) or ""))
SV.freeGraph(G)
for _, ab in ipairs(def.ablations or {}) do run(ab, "абляция") end
for _, ab in ipairs(def.controls or {}) do run(ab, "контроль") end
