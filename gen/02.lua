-- Скелет уровня 2 «Скалолаз»: отводы в шахте — крючья; подъём чередованием головы и ног.
local HOOK = { { left = "N" }, { right = "N" }, { left = "V" }, { right = "V" }, { down = "N" }, { down = "V" } }
return {
  id = 2, flat = 2, name = "Скалолаз",
  length = { 2, 4 }, pressure = 0,
  target = { moves = { 22, 38 }, states = 50000, dead = 30, fb = 2 },
  wallProb = 0.3, drainProb = 0.4,
  grid = { "#########", "#???????#", "#???????#", "#???????#", "#???????#", "#???????#", "#???????#", "#???????#", "#???????#", "#???????#" },
  objects = {
    { kind = "source", area = { 2, 2, 8, 3 }, portsOptions = { { down = "V" }, { left = "V" }, { right = "V" } } },
    { kind = "fixture", what = "shower", area = { 2, 2, 8, 3 }, portsOptions = { { down = "N" }, { left = "N" }, { right = "N" } } },
    { kind = "stub", tag = "hook", area = { 2, 4, 8, 8 }, portsOptions = HOOK },
    { kind = "stub", tag = "hook", area = { 2, 4, 8, 8 }, portsOptions = HOOK },
    { kind = "stub", tag = "hook", area = { 2, 4, 8, 8 }, portsOptions = HOOK },
  },
  lapidus = { area = { 2, 7, 8, 9 }, len = { 2, 3 } },
  near = { 1, 2, 5 },
  ablations = { { name = "у крючьев чужая резьба", flip = "hook" }, { name = "без крючьев", remove = "hook" } },
}
