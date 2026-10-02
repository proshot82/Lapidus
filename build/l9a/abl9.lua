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
  if G2.firstWin and arg[2] == "frames" and arg[3] and name:find(arg[3], 1, true) then
    local path, x = {}, G2.firstWin
    while x ~= 1 do table.insert(path, 1, x); x = G2.parent[x] end
    table.insert(path, 1, 1)
    local frames = {}
    for i, id in ipairs(path) do
      local st = R.decode(lvl2, G2.keys[id])
      local rows = {}
      for y = 1, lvl2.H do rows[y] = {} for x2 = 1, lvl2.W do local c = lvl2.cell[(y-1)*lvl2.W+x2]; rows[y][x2] = c == 1 and "#" or "." end end
      if not st.dead then for _, j in ipairs(R.jets(lvl2, st)) do for _, c in ipairs(j.cells) do local xx, yy = R.xy(lvl2, c); rows[yy][xx] = (j.dir == R.UP) and "^" or ((j.dir == R.DOWN) and "v" or ((j.dir == R.RIGHT) and ">" or "<")) end end end
      for qq, pp in ipairs(lvl2.pieces) do if st.pos[qq] ~= 0 then local xx, yy = R.xy(lvl2, st.pos[qq]); local ch = pp.movable and (pp.tag or "b"):sub(1,1) or ({ source = "S", fixture = "F", stub = "T", pipe = "=" })[pp.kind]; if pp.movable then ch = st.fixed[qq] and ch:upper() or ch:lower() end; rows[yy][xx] = ch end end
      if not st.dead then for k, c in ipairs(st.body) do local xx, yy = R.xy(lvl2, c); rows[yy][xx] = (k == #st.body) and "H" or ((k == 1) and "f" or "o") end end
      local out = { (i == 1) and "start" or ((i-1) .. R.moveName(G2.pmove[id]):gsub("heel", "f"):gsub("head", "H"):gsub(":", ""):sub(1, 3)) }
      for y = 1, lvl2.H do out[#out+1] = table.concat(rows[y]) end
      frames[#frames+1] = out
    end
    local per = 7
    for k = 1, #frames, per do
      for line = 1, #frames[k] do
        local parts = {}
        for j = k, math.min(k + per - 1, #frames) do parts[#parts+1] = string.format("%-16s", frames[j][line] or "") end
        print(table.concat(parts, ""))
      end
      print()
    end
  end
  SV.freeGraph(G2)
end
print("узкие абляции (" .. arg[1] .. "):")
if arg[2] == "frames" then run(arg[3], arg[3] == "один выход" and { mutate = F2.oneOutlet } or { filter = F2[arg[3]] }) return end
run("у гребёнки один выход вверх", { mutate = F2.oneOutlet })
run("с гребня не сдвинуть вбок", { filter = F2.noRideMove })
run("удерживаемую в столбе деталь не сдвинуть вбок", { filter = F2.noSideFromHold })
run("с гребня на гребень нельзя", { filter = F2.noCrestToCrest })
run("деталь не поднимает другую (лифт стопки)", { filter = F2.noLift })
run("стопки нет (деталь не стоит на детали в столбе)", { filter = F2.noStack })
for _, ab in ipairs(def.ablations or {}) do run("абл: " .. ab.name, ab) end
for _, ab in ipairs(def.controls or {}) do run("контр: " .. ab.name, ab) end
