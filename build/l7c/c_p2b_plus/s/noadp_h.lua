-- p2b без переходника с разметкой скептика honest (только для анализа)
local V = dofile("build/l7c/b_lift_cargo/verify2_vis.lua")
local d = dofile("build/l7c/b_lift_cargo/verify2_noadp.lua")
d.visibleLoss = V.make(d, "honest")
return d
