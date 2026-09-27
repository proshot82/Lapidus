-- Скелет уровня 3 «Мыло»: фаянс толкают только ноги, а ноги нужны у стояка.
return {
  id = 3, flat = 3, name = "Мыло",
  length = { 2, 5 }, pressure = 0,
  target = { moves = { 25, 45 }, states = 100000, dead = 35, fb = 2 },
  wallProb = 0.25, drainProb = 0.3,
  grid = { "###########", "#?????????#", "#?????????#", "#?????????#", "#?????????#", "#?????????#", "#?????????#", "#?????????#" },
  objects = {
    { kind = "source", area = { 2, 2, 10, 7 }, portsOptions = { { right = "V" }, { left = "V" }, { up = "V" }, { down = "V" } } },
    { kind = "fixture", what = "bath", area = { 2, 2, 10, 7 }, portsOptions = { { left = "N" }, { right = "N" }, { up = "N" }, { down = "N" } } },
    { kind = "porcelain", tag = "soap", area = { 2, 2, 10, 7 } },
    { kind = "porcelain", tag = "soap", area = { 2, 2, 10, 7 } },
  },
  lapidus = { area = { 2, 2, 10, 7 }, len = { 2, 3 } },
  near = { 1, 2, 6 },
  ablations = { { name = "без фаянса", remove = "soap" } },
}
