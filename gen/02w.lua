-- Уровень 2: лестница у левой стены (крючья x=2), шахта x=3..4; справа полоса 3 клетки под ловушку.
local objs = {
  { kind = "source", at = { 2, 2 }, ports = { right = "V" } },
  { kind = "fixture", what = "shower", at = { 5, 2 }, ports = { left = "N" } },
}
local th = { "N", "V", "N", "V", "N", "V" }
for i, t in ipairs(th) do objs[#objs + 1] = { kind = "stub", tag = "hook", at = { 2, 2 + i }, ports = { right = t } } end
return {
  id = 2, flat = 2, name = "Скалолаз",
  length = { 2, 4 }, pressure = 0,
  target = { moves = { 22, 38 }, states = 50000, dead = 30, fb = 2 },
  minStates = 0, searchCap = 50000, wallProb = 0.4, drainProb = 0.4, wallPenalty = 0,
  grid = {
    "#########",
    "#....???#",
    "#...????#",
    "#...????#",
    "#...????#",
    "#...????#",
    "#...????#",
    "#...????#",
    "##..????#",
    "##~~????#",
  },
  objects = objs,
  lapidus = { area = { 3, 7, 8, 9 }, len = { 2, 3 } },
  ablations = { { name = "без крючьев", remove = "hook" }, { name = "резьба крючьев", flip = "hook" } },
}
