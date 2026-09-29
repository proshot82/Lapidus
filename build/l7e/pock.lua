-- build/l7e/pock.lua N файл.lua — check.lua при пороге кармана M.POCKET = N (проверка «не на границе»: 3, 4, 5)
package.path = "./?.lua;" .. package.path
local V = require("tools.vislib")
V.POCKET = tonumber(arg[1])
arg = { arg[2] }
dofile("build/l6b/check.lua")
