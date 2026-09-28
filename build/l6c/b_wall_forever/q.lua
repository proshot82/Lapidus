-- q.lua файл.lua … — короткая строка метрик для каждого файла
package.path = "./?.lua;" .. package.path
local Q = dofile("build/l6c/b_wall_forever/quick.lua")
for i = 1, #arg do
  local ok, def = pcall(dofile, arg[i])
  if not ok then print(arg[i], "LOADERR", def) else
  local ok2, m = pcall(Q.metrics, def)
  print(string.format("%-40s %s", arg[i]:match("[^/]+$"), ok2 and Q.line(m) or ("ERR " .. tostring(m)))) end
end
