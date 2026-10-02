-- Уровень 3 «Мыло»: полка на высоте 5 (длина до 5) — без ступени из фаянса не взять;
-- мутатор расставляет фаянс, уступы, сливы и старт.
return {
  id = 3, flat = 3, name = "Мыло", length = { 2, 5 }, pressure = 0,
  target = { moves = { 25, 45 }, states = 100000, dead = 35, fb = 2 },
  minStates = 0, searchCap = 100000, wallProb = 0.22, drainProb = 0.35, wallPenalty = 0,
  grid = {
    "###########",
    "#????.....#",
    "#?????.####",
    "#?????.####",
    "#?????.####",
    "#?????.####",
    "#?????.####",
    "#?????#####",
  },
  objects = {
    { kind = "source", at = { 6, 2 }, ports = { right = "V" } },
    { kind = "fixture", what = "sink", at = { 10, 2 }, ports = { left = "N" } },
    { kind = "porcelain", tag = "soap", area = { 2, 3, 6, 7 } },
    { kind = "porcelain", tag = "soap", area = { 2, 3, 6, 7 } },
  },
  lapidus = { area = { 2, 3, 6, 7 }, len = { 2, 4 } },
  ablations = { { name = "без фаянса", remove = "soap" } },
}
