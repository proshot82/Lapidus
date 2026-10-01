-- build/l8b/fam2.lua — сборка раскладки семейства Б2 (общая для scan2.lua и ручных проб). Возвращает функцию mk.
package.path = "./?.lua;" .. package.path
local F = dofile("build/l8a/filt.lua")
return function(RR, LMAX, YQ)
return function(xx, yx, holes, pq, pn, xf, sx)
  local rows = {}
  for y = 1, 10 do rows[y] = string.rep("#", 16) end
  local function set(x, y, ch) rows[y] = rows[y]:sub(1, x - 1) .. ch .. rows[y]:sub(x + 1) end
  -- полка ряд 3: столбцы 3..xx-1 пусто; ряд 4: стены, кроме дыр и шахт (3 и xx-1)
  for x = 3, xx - 1 do set(x, 3, ".") end
  for _, h in ipairs(holes) do set(h, 4, ".") end
  set(3, 4, "."); set(xx - 1, 4, ".")
  -- комната ряды 5..9, столбцы 3..xx-1 (столбец xx занят тумбой X ниже yx; выше yx — пусто до xx-1 только)
  for y = 5, 9 do for x = 3, xx - 1 do set(x, y, ".") end end
  set(2, YQ, "."); set(xx, yx, ".")
  local objs = {
    { kind = "source", at = { 2, YQ }, ports = { right = "V" } },
    { kind = "source", at = { xx, yx }, ports = { left = "V" } },
    { kind = "fixture", what = "bath", at = { xf, 9 }, ports = { up = "V" } },
    { kind = "fitting", what = "plug", tag = "plug", at = { pq, 3 }, ports = { left = "N" } },
    { kind = "fitting", what = "nipple", tag = "nip", at = { pn, 3 }, ports = { left = "N", right = "N" } },
    { kind = "lapidus", cells = { { sx, 9 }, { sx + 1, 9 } }, head = 2 },
  }
  return { id = 8, flat = 8, name = "Брандспойт", length = { 2, LMAX }, pressure = RR, grid = rows, objects = objs,
    ablations = { { name = "брандспойт не бьёт", filter = F.noHose } } }
end
end
