-- build/l9v/g7_w83.lua — опыт скептика: g7 с замурованной клеткой (8,3) (обход «поверху» закрыт). Не кандидат, а проба.
local d = dofile("build/l9a/g7.lua")
d.grid[3] = d.grid[3]:sub(1, 7) .. "#" .. d.grid[3]:sub(9)
return d
