-- Пример формата уровня из §11 — иллюстрация, не настоящий уровень.
return {
  id = 0, flat = 1, name = "Пример формата",
  length = { 2, 4 }, pressure = 0,
  grid = {            -- # стена, . пусто, ~ слив
    "##########",
    "#........#",
    "#........#",
    "#........#",
    "#........#",
    "#........#",
    "###~######",
  },
  objects = {
    { kind = "source",    at = { 2, 6 }, ports = { right = "N" } },
    { kind = "fixture",   what = "bath", at = { 9, 6 }, ports = { left = "V" } },
    { kind = "stub",      at = { 5, 2 }, ports = { down = "N" } },
    { kind = "porcelain", at = { 7, 6 } },
    { kind = "fitting",   at = { 7, 5 }, ports = { left = "V", right = "N" } },
    { kind = "lapidus",   cells = { { 4, 6 }, { 5, 6 }, { 6, 6 } }, head = 3 },
  },
  texts = { request = "…", hints = { "…", "…", "…" } },
}
