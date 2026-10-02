-- build/l4d/check_pocket.lua файл.lua N — как build/l6b/check.lua, но с порогом кармана общей линейки M.POCKET = N.
package.path = "./?.lua;" .. package.path
require("tools.vislib").POCKET = tonumber(arg[2])
arg[2] = nil
dofile("build/l6b/check.lua")
