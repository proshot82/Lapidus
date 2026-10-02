local V = dofile("build/l7c/c_p2b_plus/qvis.lua")
local d = dofile("build/l7c/c_p2b_plus/s/q1.lua")
d.visibleLoss = V.make(d, { adpStackVisible = true })
return d
