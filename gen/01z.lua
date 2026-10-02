-- Квартира 1 «Не той стороной», поиск по новому методу: теорема — «крюк не цель, а точка опоры: повиснув на нём,
-- концы можно поменять местами». Поле 9×7, объекты ищет мутатор; абляции: без крюка и «крюк без крепления».
local hook = dofile("build/l5/hookfilter.lua")
return {
  id = 1, flat = 1, name = "Не той стороной", length = { 2, 4 }, pressure = 0,
  target = { moves = { 12, 30 }, states = 20000, dead = 25, fb = 1 },
  minStates = 0, searchCap = 20000, wallProb = 0.28, drainProb = 0.35, wallPenalty = 0.6,
  strict = { monkey = 1.0, shortest = 6 }, uniqueWin = true, preAblation = true,
  grid = {
    "#########",
    "#???????#",
    "#???????#",
    "#???????#",
    "#???????#",
    "#???????#",
    "#???????#",
  },
  objects = {
    { kind = "source", area = { 2, 2, 8, 6 }, portsOptions = { { right = "N" }, { left = "N" }, { up = "N" }, { right = "V" }, { left = "V" }, { up = "V" } } },
    { kind = "fixture", what = "bath", area = { 2, 2, 8, 6 }, portsOptions = { { left = "V" }, { right = "V" }, { left = "N" }, { right = "N" } } },
    { kind = "stub", tag = "hook", area = { 2, 2, 8, 6 }, portsOptions = { { down = "V" }, { down = "N" }, { left = "V" }, { right = "V" }, { left = "N" }, { right = "N" } } },
  },
  lapidus = { area = { 2, 2, 8, 6 }, len = { 2, 4 } },
  ablations = {
    { name = "без крюка", remove = "hook" },
    { name = "крюк без крепления", filter = hook },
  },
}
