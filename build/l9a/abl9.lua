-- build/l9a/abl9.lua файл.lua — узкие абляции роли гребёнки для любого кандидата кв. 9: «у гребёнки один выход вверх»
-- (структурно, у m2 убран выход вверх), «с гребня не сдвинуть вбок» (фильтр), «удерживаемую деталь не сдвинуть вбок»,
-- плюс абляции и контроли из файла. Печатает решаем/нерешаем и длину. Решения не печатаются.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local F = dofile("build/l9a/filt.lua")
local F2 = dofile("build/l9a/filt2.lua")
local def = dofile(arg[1])
local function run(name, ab)
  local d2 = SV.deepcopy(def); d2.ablations = nil; d2.controls = nil
  SV.applyAblation(d2, ab)
  local ok, lvl2 = pcall(R.compile, d2)
  if not ok or #R.validate(lvl2) > 0 then print(string.format("  %-45s не компилируется → нерешаем", name)) return end
  local G2 = SV.explore(lvl2, 3000000, ab.filter)
  if not G2 then print(string.format("  %-45s CAP", name)) return end
  print(string.format("  %-45s %s | состояний %d%s", name, G2.firstWin and "РЕШАЕМ" or "нерешаем", G2.n, G2.firstWin and (" | ходов " .. G2.depth[G2.firstWin]) or ""))
  io.stdout:flush()
  SV.freeGraph(G2)
end
print("узкие абляции (" .. arg[1] .. "):")
run("у гребёнки один выход вверх", { mutate = F2.oneOutlet })
run("с гребня не сдвинуть вбок", { filter = F2.noRideMove })
run("удерживаемую в столбе деталь не сдвинуть вбок", { filter = F2.noSideFromHold })
run("с гребня на гребень нельзя", { filter = F2.noCrestToCrest })
for _, ab in ipairs(def.ablations or {}) do run("абл: " .. ab.name, ab) end
for _, ab in ipairs(def.controls or {}) do run("контр: " .. ab.name, ab) end
