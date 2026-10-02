-- build/l9v2/g18_one.lua — контроль скептика: g18, у дальней клетки гребёнки (m2) нет выхода вверх (F2.oneOutlet).
local d = dofile("build/l9a/g18.lua")
for _, o in ipairs(d.objects) do if o.tag == "m2" then o.ports.up = nil end end
d.ablations = {}
return d
