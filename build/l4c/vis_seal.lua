-- build/l4c/vis_seal.lua — проверочная версия: основной видимый проигрыш + «к толкающей клетке не пройти» (карман запечатан),
-- без пометок уровня «ага» (пара, порядок). Нужна только чтобы понять, насколько основная цифра держится на кармане.
local main = dofile("build/l4c/vis_main.lua")
local v3 = dofile("build/l4c/vis_v3.lua")
local wide = dofile("build/l4c/vis_wide.lua")
return function(lvl, st)
  if main(lvl, st) then return true end
  if wide(lvl, st) then return false end -- пары и порядок оставляем скрытыми
  return v3(lvl, st)
end
