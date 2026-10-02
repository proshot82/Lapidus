-- build/l4c/wide_of.lua — обёртка для build/l6b/check.lua: кандидат из переменной CAND с широким видимым проигрышем.
-- CAND=build/l4c/k35.lua luajit build/l6b/check.lua build/l4c/wide_of.lua
local def = dofile(assert(os.getenv("CAND"), "CAND не задан"))
def.visibleLoss = dofile("build/l4c/vis_wide.lua")
return def
