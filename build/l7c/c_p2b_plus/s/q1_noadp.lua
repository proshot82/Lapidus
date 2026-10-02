local d = dofile("build/l7c/c_p2b_plus/s/q1.lua")
local keep = {}
for _, o in ipairs(d.objects) do if o.tag ~= "adp" then keep[#keep + 1] = o end end
d.objects = keep
return d
