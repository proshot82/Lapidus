-- a09 (напор 2): перевёрнутый тройник на стояке бьёт вверх (лифт) и вправо (по полу). Ванна у верхушки фонтана
-- ловит переходник. Пробка падает по правому столбу мимо ванны в правый выход; если переходник уже в ванне,
-- резьба поймает пробку на лету — ванна заглушена. Угольник ложится на пробку и глушит фонтан сбоку последним.
return {
  id = 7, flat = 7, name = "Дали напор",
  length = { 2, 5 }, pressure = 2,
  grid = {
    "########",
    "#......#",
    "#......#",
    "#..##..#",
    "#......#",
    "#......#",
    "#......#",
    "#......#",
    "########",
  },
  objects = {
    { kind = "source", at = { 4, 8 }, ports = { right = "N" } },
    { kind = "fitting", what = "tee", tag = "tee", at = { 5, 8 }, ports = { left = "V", up = "N", right = "N" } },
    { kind = "fixture", what = "bath", at = { 4, 5 }, ports = { right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 4, 7 }, ports = { left = "N", right = "N" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { 5, 3 }, ports = { left = "V" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 4, 3 }, ports = { down = "V", right = "V" } },
    { kind = "lapidus", cells = { { 2, 8 }, { 3, 8 } }, head = 2 },
  },
}
