-- p2b с широким видимым проигрышем скептика (vis.lua, режим wide) — только для проверки.
local V = dofile("build/l7c/b_lift_cargo/vis.lua")
local d = dofile("build/l7c/b_lift_cargo/p2b.lua")
d.visibleLoss = V.make("wide")
return d
