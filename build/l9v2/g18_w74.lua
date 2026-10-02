-- build/l9v2/g18_w74.lua — проба скептика: g18, клетка над верхушкой ближнего столба (7,4) замурована.
local d = dofile("build/l9a/g18.lua")
d.grid[4] = d.grid[4]:sub(1, 6) .. "#" .. d.grid[4]:sub(8)
return d
