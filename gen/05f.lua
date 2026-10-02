-- Квартира 5 «Лишний выход», минимальная раскладка по методу «теорема → поле не больше нужного».
-- Теорема: заглушка — сначала лестница, потом пробка. Тройник на полке (5,2), шахта (4,2–5), ступенька — заглушка на (4,6);
-- тройник падает по столбу 6 на стояк (7,6), его левый выход над сливом (5,7); полотенцесушитель (8,4).
local step = dofile("build/l5/stepfilter.lua")
return {
  id = 5, flat = 5, name = "Лишний выход", length = { 2, 4 }, pressure = 0,
  target = { moves = { 14, 40 }, states = 100000, dead = 35, fb = 1 },
  minStates = 0, searchCap = 100000, wallProb = 0.3, drainProb = 0.4, wallPenalty = 0.6,
  strict = { monkey = 1.0, shortest = 4 }, uniqueWin = true, preAblation = true,
  grid = {
    "#########",
    "#??...###",
    "#??.#.###",
    "#??.#...#",
    "#??.#..##",
    "#??....##",
    "#??#~####",
  },
  objects = {
    { kind = "source", at = { 7, 6 }, ports = { left = "N" } },
    { kind = "fixture", what = "dryer", at = { 8, 4 }, ports = { left = "N" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 5, 2 }, ports = { right = "V", left = "V", up = "V" } },
    { kind = "fitting", what = "plug", tag = "plug", area = { 2, 2, 4, 6 }, ports = { right = "N" } },
  },
  lapidus = { area = { 2, 2, 4, 6 }, len = { 2, 4 } },
  ablations = {
    { name = "ступенька запрещена", filter = step },
    { name = "тройник заглушён заранее", remove = "plug",
      mutate = function(d) for _, o in ipairs(d.objects) do if o.tag == "tee" then o.ports.left = nil end end end },
  },
}
