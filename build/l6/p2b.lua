local d = dofile("build/l6/p2.lua")
table.insert(d.objects, 3, { kind = "fitting", what = "nipple", tag = "nip", at = { 6, 4 }, ports = { up = "N", down = "N" } })
return d
