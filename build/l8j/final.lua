-- Квартира 8 «Гусеница» — финалист раунда l8j (02.10.2026), раскладка p2 (из n13). Сменяет напорную «Гребёнку».
-- Проверка: luajit build/l6b/check.lua build/l8j/final.lua; отчёт — build/l8j/REPORT.md. Решение здесь не пишется.
-- Видимый проигрыш: общая линейка tools/vislib.lua + build/l8j/vis.lua (washOk: мыло в решении не нужно до конца).
local okV, vis = pcall(dofile, "build/l8j/vis.lua")
local R = require("core.rules")
local function tagOf(lvl, tag) for q, p in ipairs(lvl.pieces) do if p.tag == tag then return q end end end
local function onBody(st, c)
  for _, b in ipairs(st.body) do if b == c then return true end end
  return false
end
-- «везти на спине нельзя»: запрещён ход, который сдвигает муфту вбок, пока она лежит на Лапидусе
local function noConveyor(lvl, st, ns)
  local q = tagOf(lvl, "cpl")
  local a, b = st.pos[q], ns.pos[q]
  if a == 0 or b == 0 or st.fixed[q] then return true end
  local ax, ay = R.xy(lvl, a)
  local bx, by = R.xy(lvl, b)
  if ax ~= bx and onBody(st, lvl.nb[a][R.DOWN]) then return false end
  return true
end
-- «мимо стояка — только верхом»: муфта не опускается ниже ряда 4 правее мыла
local function noDip(lvl, st, ns)
  local q = tagOf(lvl, "cpl")
  local c = ns.pos[q]
  if c == 0 or ns.fixed[q] then return true end
  local x, y = R.xy(lvl, c)
  return not (x >= 7 and y >= 5)
end
return {
  visibleLoss = okV and vis or nil,
  washOk = true,
  mustLift = { "cpl" },
  id = 8, flat = 8, name = "Гусеница",
  length = { 3, 5 }, pressure = 0, tile = "blue",
  target = { moves = { 15, 40 }, states = 100000, dead = 25, fb = 2 },
  grid = {
    "############",
    "#########.##",
    "########..##",
    "#.#.......##",
    "#.........##",
    "#####.....##",
    "############",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 10, 2 }, ports = { down = "N" } },
    { kind = "source", at = { 9, 3 }, ports = { down = "N" } },
    { kind = "fitting", what = "coupling", tag = "cpl", at = { 5, 4 }, ports = { up = "V", down = "V" } },
    { kind = "porcelain", tag = "soap", at = { 5, 5 } },
    { kind = "lapidus", cells = { { 4, 5 }, { 3, 5 }, { 2, 5 }, { 2, 4 } }, head = 4 },
  },
  ablations = {
    { name = "без мыла", remove = "soap" },
    { name = "без муфты", remove = "cpl" },
    { name = "везти на спине нельзя", filter = noConveyor },
    { name = "мимо стояка только верхом", filter = noDip },
    { name = "без ямки под мылом", mutate = function(d) d.grid[6] = "######....##" end },
  },
  texts = {
    request = "Колонку повесили под самый потолок, муфту оставили на мыле и ушли. Донести её некому: мастер ничего не носит.",
    card = nil, -- новых правил нет
    hints = {
      "Ничего не носит — но возит: муфта едет на спине, если толкать её своим же концом и подстилать под неё себя. Под стояком — только низом.",
      "Ваш звонок очень важен для нас. Уточняем, что у вас висит над дорогой.",
      "Мастер выехал. Говорит: что проехало под стояком поверху, то к стояку и прикипело.",
    },
  },
}
