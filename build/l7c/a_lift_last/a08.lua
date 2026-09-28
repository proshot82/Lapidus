-- a08 (напор 2): ванна висит у верхушки фонтана, вход вправо (В). Переходник Н/Н фонтан поднимает к ванне —
-- резьба ловит его на лету. Угольник (низ В, вправо В) глушит фонтан сбоку последним; в него встают ноги.
return {
  id = 7, flat = 7, name = "Дали напор",
  length = { 2, 5 }, pressure = 2,
  grid = {
    "##########",
    "#........#",
    "#........#",
    "#........#",
    "#........#",
    "#........#",
    "#.....#..#",
    "##########",
  },
  objects = {
    { kind = "source", at = { 6, 7 }, ports = { up = "N" } },
    { kind = "fixture", what = "bath", at = { 5, 4 }, ports = { right = "V" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { 7, 6 }, ports = { left = "N", right = "N" } },
    { kind = "fitting", what = "elbow", tag = "elb", at = { 7, 5 }, ports = { down = "V", right = "V" } },
    { kind = "lapidus", cells = { { 9, 7 }, { 9, 6 } }, head = 2 },
  },
}
