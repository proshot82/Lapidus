package.path = "./?.lua;" .. package.path
return dofile("build/l3c/vis.lua").make({ { 7, 7 } }, false, { e = true })
