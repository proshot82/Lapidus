-- как t.lua, но с LMIN и PRESS из окружения
local d = dofile("build/l7c/b_lift_cargo/probe/t.lua")
d.length = { tonumber(os.getenv("LMIN") or 2), tonumber(os.getenv("LMAX") or 5) }
d.pressure = tonumber(os.getenv("PRESS") or 3)
return d
