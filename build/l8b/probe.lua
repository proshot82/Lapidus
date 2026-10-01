-- build/l8b/probe.lua — опыты на core/rules.lua для кв. 8 (поиск l8b): потолочный кран и вертикальный ниппель.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local function show(lvl, st, label)
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x]; rows[y][x] = c == 1 and "#" or (c == 2 and "~" or ".") end end
  for _, j in ipairs(R.jets(lvl, st)) do for _, c in ipairs(j.cells) do local x, y = R.xy(lvl, c); rows[y][x] = ({ "^", ">", "v", "<" })[j.dir] end end
  for q, p in ipairs(lvl.pieces) do if st.pos[q] ~= 0 then local x, y = R.xy(lvl, st.pos[q]); local ch = p.kind == "source" and "S" or (p.kind == "fixture" and "F" or (p.kind == "stub" and "T" or (p.tag or "?"):sub(1,1))); if p.movable then ch = st.fixed[q] and ch:upper() or ch:lower() end; rows[y][x] = ch end end
  for i, c in ipairs(st.body) do local x, y = R.xy(lvl, c); rows[y][x] = (i == #st.body) and "H" or ((i == 1) and "f" or "o") end
  print(label .. (R.isWin(lvl, st) and "  ПОБЕДА" or "") .. (st.dead and " СМЫТ" or ""))
  for y = 1, lvl.H do print("   " .. table.concat(rows[y])) end
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
-- 1b: мокрый якорь (кран слева, ноги), голова бьёт вправо вдоль полки: вертикальный ниппель уходит под потолочный кран
run("1b. вертикальный ниппель струёй вбок под потолочный кран (якорь мокрый)", {
  length = { 2, 6 }, pressure = 2,
  grid = { "###########", "#.........#", "#.........#", "#.###.###.#", "#.........#", "#.........#", "#.........#", "###########" },
  objects = {
    { kind = "source", at = { 6, 2 }, ports = { down = "V" } },
    { kind = "source", at = { 2, 5 }, ports = { right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 5, 3 }, ports = { up = "N", down = "N" } },
    { kind = "fixture", what = "bath", at = { 9, 6 }, ports = { up = "V" } },
    { kind = "lapidus", cells = { { 3, 5 }, { 3, 4 }, { 3, 3 } }, head = 3 },
  } }, { "head:right" })
-- 2b: то же с пробкой (Н вверх)
run("2b. пробка (Н вверх) струёй вбок под потолочный кран", {
  length = { 2, 6 }, pressure = 2,
  grid = { "###########", "#.........#", "#.........#", "#.###.###.#", "#.........#", "#.........#", "#.........#", "###########" },
  objects = {
    { kind = "source", at = { 6, 2 }, ports = { down = "V" } },
    { kind = "source", at = { 2, 5 }, ports = { right = "V" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { 5, 3 }, ports = { up = "N" } },
    { kind = "fixture", what = "bath", at = { 9, 6 }, ports = { up = "V" } },
    { kind = "lapidus", cells = { { 3, 5 }, { 3, 4 }, { 3, 3 } }, head = 3 },
  } }, { "head:right" })
-- 4b: голова снизу к ниппелю под потолочным краном; тело через дыру на полку; ноги бьют вправо — пробка под второй кран
run("4b. голова к ниппелю снизу, ноги на полке — брандспойт вправо", {
  length = { 2, 6 }, pressure = 3,
  grid = { "############", "#..........#", "#..........#", "#.###.####.#", "#..........#", "#..........#", "#..........#", "############" },
  objects = {
    { kind = "source", at = { 6, 2 }, ports = { down = "V" } },
    { kind = "source", at = { 10, 2 }, ports = { down = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 6, 3 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { 9, 3 }, ports = { up = "N" } },
    { kind = "fixture", what = "bath", at = { 2, 6 }, ports = { up = "V" } },
    { kind = "lapidus", cells = { { 6, 4 }, { 6, 5 }, { 7, 5 }, { 7, 4 }, { 7, 3 } }, head = 1 },
  } }, { "heel:right" })
