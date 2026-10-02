-- abfr.lua файл N — пишет во временный файл вариант с N-й абляцией (для просмотра кадров check.lua)
package.path = "./?.lua;" .. package.path
local SV = require("solver.solve")
local def = dofile(arg[1])
local ab = def.ablations[tonumber(arg[2])]
local d = SV.deepcopy(def); d.ablations = nil
SV.applyAblation(d, ab)
local f = io.open(arg[3], "w")
f:write("local d = dofile(\"" .. arg[1] .. "\")\nd.ablations = nil\nd.grid = {\n")
for _, r in ipairs(d.grid) do f:write("  \"" .. r .. "\",\n") end
f:write("}\nlocal keep = {}\nfor _, o in ipairs(d.objects) do if o.tag ~= \"" .. (ab.remove or "") .. "\" then keep[#keep+1] = o end end\n")
if ab.mutate then f:write("local k2 = {} for _, o in ipairs(keep) do local x = d.grid[o.at and o.at[2] or 1]; if not (o.at and x:sub(o.at[1], o.at[1]) == '#') then k2[#k2+1] = o end end keep = k2\n") end
f:write("d.objects = keep\nreturn d\n")
f:close()
