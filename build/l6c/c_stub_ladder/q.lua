-- q.lua файл1.lua [файл2.lua ...] — строка метрик и провалы ворот по каждому файлу (без решений).
package.path = "./?.lua;" .. package.path
local GT = dofile("build/l6c/c_stub_ladder/gates.lua")
for _, f in ipairs(arg) do
  local def = dofile(f)
  local r = GT.eval(def)
  print(f:match("([^/]+)%.lua$") .. ": " .. r.line)
  print("   провалы: " .. (#r.fails > 0 and table.concat(r.fails, ", ") or "нет") .. (r.safe and ("  | безоп.: " .. r.safe) or "") .. (r.deepList and ("  | глуб.: " .. r.deepList) or ""))
end
