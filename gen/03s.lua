-- Уровень 3 «Мыло»: полка справа выше досягаемого; ступень — только фаянс, толкают его только ноги.
return {
  id = 3, flat = 3, name = "Мыло",
  length = { 2, 5 }, pressure = 0,
  target = { moves = { 25, 45 }, states = 100000, dead = 35, fb = 2 },
  minStates = 0, searchCap = 60000, wallProb = 0.3, drainProb = 0.4, wallPenalty = 0,
  grid = {
    "###########",
    "#??????...#",
    "#?????....#",
    "#?????.####",
    "#?????.####",
    "#......####",
    "#......####",
    "#???????###",
  },
  objects = {
    { kind = "source", area = { 8, 2, 10, 3 }, portsOptions = { { left = "V" }, { down = "V" }, { right = "V" } } },
    { kind = "fixture", what = "bath", area = { 6, 2, 10, 3 }, portsOptions = { { left = "N" }, { right = "N" }, { down = "N" } } },
    { kind = "porcelain", tag = "soap", area = { 2, 4, 6, 7 } },
    { kind = "porcelain", tag = "soap", area = { 2, 4, 6, 7 } },
  },
  near = { 1, 2, 3 },
  lapidus = { area = { 2, 5, 6, 7 }, len = { 2, 4 } },
  ablations = { { name = "без фаянса", remove = "soap" } },
}
