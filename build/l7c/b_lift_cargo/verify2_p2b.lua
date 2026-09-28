-- verify2_p2b.lua — p2b с самой широкой, по мнению скептика, ещё честной разметкой видимого проигрыша
-- (verify2_vis.lua, режим honest: авторские A–C + D, E, Ca, Sr, N). Только для проверки; решений не содержит.
local V = dofile("build/l7c/b_lift_cargo/verify2_vis.lua")
local d = dofile("build/l7c/b_lift_cargo/p2b.lua")
d.visibleLoss = V.make(d, "honest")
return d
