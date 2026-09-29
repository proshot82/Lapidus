-- nvis.lua — мерка новичка для семейства «паром» (обёртка над fvis.lua с opts.novice = true), для экспериментов.
local V = dofile("build/l7c/c_p2b_plus/fvis.lua")
local M = {}
function M.why(def) return V.why(def, { novice = true }) end
function M.make(def) return V.make(def, { novice = true }) end
return M
