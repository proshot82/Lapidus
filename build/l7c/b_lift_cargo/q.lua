-- q.lua файл1.lua [файл2.lua ...] — строка метрик и провалы ворот по каждому файлу (без решений).
package.path = "./?.lua;" .. package.path
local GT = dofile("build/l7c/b_lift_cargo/gates.lua")
local quick = os.getenv("QUICK")
for _, f in ipairs(arg) do
  local def = dofile(f)
  local r = GT.eval(def, { nostrict = quick and true or nil, noabl = quick and true or nil })
  print(f:match("([^/]+)%.lua$") .. ": " .. r.line)
  print("   провалы: " .. (#r.fails > 0 and table.concat(r.fails, ", ") or "нет") .. (r.safe and ("  | безоп.: " .. r.safe) or "") .. (r.deepList and ("  | глуб.: " .. r.deepList) or ""))
end
