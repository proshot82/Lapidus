-- build/l2d/try.lua — быстрый прогон одной ASCII-раскладки (из файла-таблицы) или файлов уровней.
-- luajit build/l2d/try.lua файл.lua [файл2.lua ...]   — файл возвращает def уровня (полный формат) ИЛИ { rows = {...}, opts = {...} }
package.path = "./?.lua;" .. package.path
local EV = dofile("build/l2d/eval.lua")
local MK = dofile("build/l2d/mk.lua")
for _, f in ipairs(arg) do
  local d = dofile(f)
  if d.rows then d = MK.build(d.rows, d.opts) end
  local r = EV.eval(d, { ablations = true })
  print(f:match("([^/]+)%.lua$") .. ": " .. r.line)
  print("   провалы: " .. (#r.fails > 0 and table.concat(r.fails, ", ") or "нет") .. (r.safe and ("  | безоп.: " .. r.safe) or "") .. (r.deepList and ("  | глуб.: " .. r.deepList) or ""))
  if r.abl then print("   абляции: " .. r.abl) end
end
