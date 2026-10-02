local d = dofile("build/l6/p2.lua")
table.insert(d.objects, 3, { kind = "fitting", what = "nipple", tag = "nip", at = { 3, 5 }, ports = { up = "N", down = "N" } })
for _, o in ipairs(d.objects) do if o.kind == "lapidus" then o.cells = { {5,4},{5,5},{5,6},{4,6},{3,6} }; o.head = 5 end end
return d
