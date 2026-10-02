-- build/l8v/probe.lua — скептик кв. 8: прямые опыты на core/rules.lua по спорным пунктам физики брандспойта.
-- Каждый опыт — крошечная раскладка, одно состояние, один ход; печатаются положения деталей и струи до/после.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local function show(lvl, st, label)
  local piece = R.occupancy(st)
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x]; rows[y][x] = c == 1 and "#" or "." end end
  for q, p in ipairs(lvl.pieces) do if st.pos[q] ~= 0 then local x, y = R.xy(lvl, st.pos[q]); local ch = p.sym or (p.kind == "source" and "S" or (p.kind == "fixture" and "F" or (p.what or "?"):sub(1,1))); if p.movable then ch = st.fixed[q] and ch:upper() or ch:lower() end; rows[y][x] = ch end end
  for i, c in ipairs(st.body) do local x, y = R.xy(lvl, c); rows[y][x] = (i == #st.body) and "H" or ((i == 1) and "f" or "o") end
  local jets = R.jets(lvl, st)
  local js = {}
  for _, j in ipairs(jets) do local x, y = R.xy(lvl, j.cell); js[#js+1] = string.format("%s(%d,%d)%s×%d", j.lapidus and ("Лапидус-" .. j.lapidus) or "течь", x, y, R.DIRNAME[j.dir], #j.cells) end
  print(label .. "  струи: " .. (#js > 0 and table.concat(js, " ") or "нет"))
  for y = 1, lvl.H do print("   " .. table.concat(rows[y])) end
  local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then local x, y = R.xy(lvl, st.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag, x, y, st.fixed[q] and "F" or "") end end
  print("   детали: " .. table.concat(t, " ") .. (R.isWin(lvl, st) and "  ПОБЕДА" or ""))
end
local function run(title, def, moves)
  print("=== " .. title)
  local lvl = R.compile(def)
  local st = R.newState(lvl)
  show(lvl, st, "старт")
  for _, m in ipairs(moves) do
    local w, d = m:match("^(%a+):(%a+)$")
    local ns, kind = R.move(lvl, st, w, R.DIRINDEX[d])
    if not ns then print("   ход " .. m .. " отказ: " .. tostring(kind)) else st = ns; show(lvl, st, "после " .. m .. " (" .. kind .. ")") end
  end
end
-- Опыт 1: пробка на полке, брандспойт бьёт её влево; она падает в шахту над чужой течью и прикручивается на лету.
run("1. пробка струёй в шахту над чужой течью → прикручивается на лету (резьба сильнее струи)", {
  length = { 2, 5 }, pressure = 2,
  grid = { "##########", "#........#", "#..#.....#", "#........#", "#........#", "##########" },
  objects = {
    { kind = "source", at = { 2, 4 }, ports = { right = "V" } },
    { kind = "source", at = { 8, 4 }, ports = { left = "N" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { 4, 2 }, ports = { left = "N" } },
    { kind = "fixture", what = "bath", at = { 8, 5 }, ports = { left = "V" } },
    { kind = "lapidus", cells = { { 7, 4 }, { 6, 4 }, { 6, 3 }, { 6, 2 } }, head = 1 },
  } }, { "heel:left" })
-- Опыт 2: то же с ниппелем (Н,Н): прикручивается к выходу В, течь переходит на его свободный порт.
run("2. ниппель к выходу В: прикручен, течь переехала на его свободный порт", {
  length = { 2, 5 }, pressure = 2,
  grid = { "##########", "#........#", "#..#.....#", "#........#", "#........#", "##########" },
  objects = {
    { kind = "source", at = { 2, 4 }, ports = { right = "V" } },
    { kind = "source", at = { 8, 4 }, ports = { left = "N" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 4, 2 }, ports = { left = "N", right = "N" } },
    { kind = "fixture", what = "bath", at = { 8, 5 }, ports = { left = "V" } },
    { kind = "lapidus", cells = { { 7, 4 }, { 6, 4 }, { 6, 3 }, { 6, 2 } }, head = 1 },
  } }, { "heel:left" })
-- Опыт 3: деталь между встречными горизонтальными струями (чужая вправо, брандспойт влево) — толчки гасятся; убрали брандспойт — уехала.
run("3. деталь во встречных струях стоит; без встречной струи уезжает", {
  length = { 2, 5 }, pressure = 2,
  grid = { "##########", "#........#", "#........#", "#........#", "#..#.....#", "##########" },
  objects = {
    { kind = "source", at = { 2, 4 }, ports = { right = "V" } },
    { kind = "source", at = { 8, 4 }, ports = { left = "N" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { 4, 4 }, ports = { up = "N" } },
    { kind = "fixture", what = "bath", at = { 8, 5 }, ports = { left = "V" } },
    { kind = "lapidus", cells = { { 7, 4 }, { 6, 4 } }, head = 1 },
  } }, { "heel:up" })
-- Опыт 4а: брандспойт вверх — столб: деталь висит на высоте R+1 над соплом; увели сопло — упала (на тело).
run("4а. столб брандспойта держит деталь на весу (R+1); сопло ушло — деталь упала", {
  length = { 2, 5 }, pressure = 2,
  grid = { "##########", "#........#", "#........#", "#........#", "#........#", "#........#", "#........#", "##########" },
  objects = {
    { kind = "source", at = { 8, 6 }, ports = { left = "N" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { 5, 4 }, ports = { down = "N" } },
    { kind = "fixture", what = "bath", at = { 8, 7 }, ports = { left = "V" } },
    { kind = "lapidus", cells = { { 7, 6 }, { 6, 6 }, { 5, 6 }, { 5, 5 } }, head = 1 },
  } }, { "heel:down" })
-- Опыт 4б: то же, но у вершины столба проходит чужая горизонтальная струя — деталь сдувает вбок с вершины.
run("4б. у вершины столба чужая струя: деталь сдувает с вершины вбок", {
  length = { 2, 5 }, pressure = 2,
  grid = { "##########", "#........#", "#........#", "#........#", "#........#", "#........#", "#........#", "##########" },
  objects = {
    { kind = "source", at = { 8, 6 }, ports = { left = "N" } },
    { kind = "source", at = { 3, 2 }, ports = { right = "V" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { 5, 4 }, ports = { down = "N" } },
    { kind = "fixture", what = "bath", at = { 8, 7 }, ports = { left = "V" } },
    { kind = "lapidus", cells = { { 7, 6 }, { 6, 6 }, { 5, 6 }, { 5, 5 } }, head = 1 },
  } }, { })
