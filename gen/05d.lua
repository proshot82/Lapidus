-- Квартира 5, локальный поиск вокруг лучших кандидатов (колонна под полкой, выемка над сливом):
-- свободнее левая часть и сливы; цель — третья ложная ветка при прочих воротах.
return {
  id = 5, flat = 5, name = "Лишний выход", length = { 2, 5 }, pressure = 0,
  target = { moves = { 35, 60 }, states = 500000, dead = 45, fb = 3 },
  minStates = 0, searchCap = 200000, wallProb = 0.3, drainProb = 0.4, wallPenalty = 0,
  strict = { monkey = 1.0, shortest = 4 }, uniqueWin = true, preAblation = true,
  grid = {
    "############",
    "#????...####",
    "#????.#.####",
    "#????.#...F#",
    "#????.#.####",
    "#????...?..#",
    "#????....###",
    "#????#~#####",
  },
  objects = {
    { kind = "source", at = { 9, 7 }, ports = { left = "N" } },
    { kind = "fixture", what = "dryer", at = { 11, 4 }, ports = { left = "N" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 7, 2 }, ports = { right = "V", left = "V", up = "V" } },
    { kind = "fitting", what = "plug", tag = "plug", area = { 2, 3, 5, 7 }, ports = { right = "N" } },
  },
  lapidus = { area = { 2, 3, 8, 7 }, len = { 2, 5 } },
  init = { "build/gen5f/05_c1.lua", "build/gen5f/05_c2.lua", "build/gen5e/05_c3.lua" },
  ablations = {
    { name = "тройник заглушён заранее", remove = "plug",
      mutate = function(d) for _, o in ipairs(d.objects) do if o.tag == "tee" then o.ports.left = nil end end end },
  },
}
