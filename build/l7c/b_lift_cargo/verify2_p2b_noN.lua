-- verify2_p2b_noN.lua — p2b с разметкой скептика без самого спорного правила N («ниппель в основании раньше
-- стопки»): verify2_vis.lua, режим honest-N. Только для проверки; решений не содержит.
local V = dofile("build/l7c/b_lift_cargo/verify2_vis.lua")
local d = dofile("build/l7c/b_lift_cargo/p2b.lua")
d.visibleLoss = V.make(d, "honest-N")
return d
