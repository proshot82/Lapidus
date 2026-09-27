local M = dofile("build/l6/mk.lua")
local d = dofile("build/l6/p1.lua")
-- nipple on lapidus back: put nipple above (7,7)?? add object
table.insert(d.objects, 3, { kind = "fitting", what = "nipple", tag = "nip", at = { 8, 6 }, ports = { up = "N", down = "N" } })
return d
