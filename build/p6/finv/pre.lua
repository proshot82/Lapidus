-- муфта сразу на стояке (проверка: нужна ли передача, если первая деталь уже стоит)
local d = dofile("build/p6/fin/final.lua")
for _, o in ipairs(d.objects) do if o.tag == "cpl" then o.at = { 9, 6 } end end
d.ablations = { d.ablations[5] }
return d
