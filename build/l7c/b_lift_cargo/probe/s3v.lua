local V = dofile("build/l7c/b_lift_cargo/vis.lua")
local d = dofile("build/l7c/b_lift_cargo/probe/s3.lua")
d.visibleLoss = V.make(os.getenv("VIS") or "mine")
return d
