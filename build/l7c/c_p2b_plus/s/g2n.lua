local V = dofile("build/l7c/c_p2b_plus/nvis.lua")
local d = dofile("build/l7c/c_p2b_plus/s/g2.lua")
d.visibleLoss = V.make(d)
return d
