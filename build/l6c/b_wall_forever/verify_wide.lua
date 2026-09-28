-- verify_wide.lua — проверка b11 (скептик): тот же уровень, visibleLoss шире.
-- Добавлено: «гнездо стояка занято прикрученной муфтой, а ниппель ещё наверху» — путь по верхнему ходу
-- перекрыт закреплённой деталью, а единственный другой спуск (левый колодец) кладёт ниппель в угол к стене,
-- что видно на один шаг вперёд (та же картина, что уже считается видимой после падения).
local base = dofile("build/l6c/b_wall_forever/b11.lua")
local vis = base.visibleLoss
base.visibleLoss = function(lvl, st)
  if vis(lvl, st) then return true end
  local sock = 2 * lvl.W + 6
  local cf, pn
  for q, p in ipairs(lvl.pieces) do
    if p.tag == "upc" then cf = st.fixed[q] and st.pos[q] == sock end
    if p.tag == "pn" then pn = q end
  end
  if cf and not st.fixed[pn] and st.pos[pn] ~= 0 and st.pos[pn] <= 3 * lvl.W then return true end
  return false
end
return base
