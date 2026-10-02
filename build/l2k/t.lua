-- t.lua <файл> — быстрые метрики + абляции (обёртка над build/l2k/ev2.lua)
package.path = "./?.lua;" .. package.path
local EV = dofile("build/l2k/ev2.lua")
for i = 1, #arg do print(arg[i] .. ": " .. EV.line(dofile(arg[i]), 2000000)) end
