local V = dofile("build/l7c/c_p2b_plus/fvis.lua")
local d = dofile("build/l7c/c_p2b_plus/s/r3e.lua")
d.visibleLoss = V.make(d)
return d
