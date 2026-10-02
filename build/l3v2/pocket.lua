-- build/l3v2/pocket.lua файл — доля скрытых при кармане 3/4/5/6 (общая линейка tools/vislib.lua)
local L = dofile("build/l7v_g/lib.lua")
local path = arg[1] or "build/l3d/s8.lua"
for _, p in ipairs({ 3, 4, 5, 6, 8, 12 }) do
  print("карман " .. p .. ": " .. L.fmt(L.metrics(dofile(path), { pocket = p })))
end
