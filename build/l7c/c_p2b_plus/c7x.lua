-- c7x.lua — c7 с разметкой ЗНАТОКА (fvis.lua: плюс неверный порядок в стопке, ниппель не на месте, неверные пары, «следующий толчок») — для сведения.
local V = dofile("build/l7c/c_p2b_plus/fvis.lua")
local d = dofile("build/l7c/c_p2b_plus/c7.lua")
d.visibleLoss = V.make(d)
return d
