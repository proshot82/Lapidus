-- Квартира 5 «Лишний выход», строгий поиск. Ядро авторское: тройник на полке (7,2) сбрасывается
-- только толчком вправо с высоты 5 — стоя на заглушке у полки; падает по столбу 8 на стояк;
-- левый выход тройника висит над сливом, заглушка ловится на резьбу только после установки тройника.
-- Правая верхняя часть закрыта: стояк и полотенцесушитель не должны служить ступенькой.
return {
  id = 5, flat = 5, name = "Лишний выход", length = { 2, 5 }, pressure = 0,
  target = { moves = { 35, 60 }, states = 500000, dead = 45, fb = 3 },
  minStates = 0, searchCap = 200000, wallProb = 0.3, drainProb = 0.35, wallPenalty = 0,
  strict = { monkey = 1.0, shortest = 4 }, uniqueWin = true, preAblation = true,
  grid = {
    "############",
    "#????...####",
    "#.....#.####",
    "#?....?....#",
    "#??...?.#??#",
    "#??...?.???#",
    "#???.....??#",
    "#????#~#####",
  },
  objects = {
    { kind = "source", at = { 9, 7 }, ports = { left = "N" } },
    { kind = "fixture", what = "dryer", at = { 11, 4 }, ports = { left = "N" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 7, 2 }, ports = { right = "V", left = "V", up = "V" } },
    { kind = "fitting", what = "plug", tag = "plug", area = { 2, 3, 6, 7 }, ports = { right = "N" } },
  },
  lapidus = { area = { 2, 2, 11, 7 }, len = { 2, 4 } },
  ablations = {
    { name = "тройник заглушён заранее", remove = "plug",
      mutate = function(d) for _, o in ipairs(d.objects) do if o.tag == "tee" then o.ports.left = nil end end end },
  },
}
