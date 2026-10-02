-- build/l9v2/uniq.lua файл.lua — единственность: выигрышные состояния и различные конфигурации деталей среди них
-- (позы Лапидуса не печатаются — только число и чем различаются: детали / длина тела). Только метрики.
local L = dofile("build/l9v2/lib.lua")
local S = L.load(arg[1])
local cf, lens, n = {}, {}, 0
for i = 1, S.n do if S.flag[i] == 1 then n = n + 1
  local s = S:st(i)
  cf[S:cfg(s)] = true
  lens[#s.body] = (lens[#s.body] or 0) + 1 end end
local k = 0; for _ in pairs(cf) do k = k + 1 end
local lt = {}; for l, c in pairs(lens) do lt[#lt+1] = l .. ":" .. c end
print(string.format("выигрышных состояний %d, различных конфигураций деталей %d, длины тела в победе [%s]", n, k, table.concat(lt, " ")))
S:free()
