-- m7 (кв. 6 «Намертво», направление C «лестница на глухом отводе»). Решения здесь нет — только замысел.
-- Замысел M7 (развитие M5 ради запаса по видимому проигрышу): муфту к стояку толкают из «кармана» в полу, а попасть
-- в карман можно только через клетку над отводом. Ступенька на отводе не занимает место толчка, а отрезает к нему
-- дорогу — клетка за муфтой остаётся пустой, и с одного взгляда тупик не виден. Ступенька — переходник (В снизу,
-- Н сверху): стоять на ней можно только ногами вниз, поэтому к ниппелю наверх приходит голова.
return {
  visibleLoss = dofile("build/l6c/c_stub_ladder/vis_m.lua"),
  lift = { B = 3 }, slide = { A = true, C = true },
  ablations = dofile("build/l6c/c_stub_ladder/abl_m.lua"),
  id = 6, flat = 6, name = "Намертво", length = { 3, 4 }, pressure = 0, tile = "mustard",
  grid = {
    "##########",
    "##.#######",
    "##....####",
    "##..#.####",
    "##..#.####",
    "##..#...##",
    "##......##",
    "##.##.####",
    "##########",
  },
  objects = {
    { kind = "fixture", what = "heater", at = { 3, 2 }, ports = { down = "V" } },
    { kind = "source", at = { 3, 8 }, ports = { up = "N" } },
    { kind = "stub", at = { 6, 8 }, ports = { up = "N" } },
    { kind = "fitting", what = "nipple", tag = "B", at = { 5, 3 }, ports = { up = "N", down = "N" } },
    { kind = "fitting", what = "coupling", tag = "C", at = { 4, 7 }, ports = { up = "V", down = "V" } },
    { kind = "fitting", what = "reducer", tag = "A", at = { 7, 7 }, ports = { up = "N", down = "V" } },
    { kind = "lapidus", cells = { { 8, 7 }, { 8, 6 }, { 7, 6 } }, head = 3 },
  },
}
