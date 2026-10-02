-- build/l9v2/g18_wallL.lua — проба скептика: g18, у глухого отвода под карнизом (stubL) нет резьбы — его клетка просто стена.
local d = dofile("build/l9a/g18.lua")
for i, o in ipairs(d.objects) do if o.tag == "stubL" then table.remove(d.objects, i) break end end
d.grid[6] = d.grid[6]:sub(1, 5) .. "#" .. d.grid[6]:sub(7)
return d
