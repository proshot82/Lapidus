-- build/l3v3/entry.lua [файл] — что после входа в скрытый класс: умная обезьяна из состояния сразу после ошибки
-- (сколько ходов в среднем до видимого), и состав скрытой области: сколько в ней состояний с мылом на полке и
-- где Лапидус (блуждание), и сколько ходов из скрытых ведут в видимое.
local L = dofile("build/l3v3/lib.lua")
local ctx = L.load(arg[1] or "levels/03.lua", 4)
local G = ctx.G
-- вход с шага 0
local entry
for _, j in ipairs(L.edges(ctx, 1)) do if L.status(ctx, j) == "hid" then entry = j end end
assert(entry)
-- умная обезьяна (не делает видимо проигрышных ходов) из entry: распределение времени до «нет невидимых ходов» = вскрытия
local p, revealed = { [entry] = 1.0 }, {}
local T = 40
for t = 1, T do
  local np = {}
  for i, pr in pairs(p) do
    local cand = {}
    for _, j in ipairs(L.edges(ctx, i)) do if G.flag[j] ~= 2 and not ctx.VL.newbie[j] then cand[#cand + 1] = j end end
    if #cand == 0 then revealed[t] = (revealed[t] or 0) + pr else
      for _, j in ipairs(cand) do np[j] = (np[j] or 0) + pr / #cand end
    end
  end
  p = np
end
local left = 0 for _, pr in pairs(p) do left = left + pr end
local parts = {}
for t = 1, T do if revealed[t] then parts[#parts + 1] = string.format("%d:%.0f%%", t, 100 * revealed[t]) end end
print("умная обезьяна после ошибки: ход, на котором все ходы видимо проигрышные → " .. table.concat(parts, " ") .. string.format(" | ещё блуждает после %d ходов: %.0f %%", T, 100 * left))
-- доля ходов из скрытых состояний: в скрытые / в видимые / смыт
local c = { hid = 0, vis = 0, wash = 0 }
for i = 1, G.n do if L.status(ctx, i) == "hid" then for _, j in ipairs(L.edges(ctx, i)) do local s = L.status(ctx, j); c[s] = (c[s] or 0) + 1 end end end
print(string.format("рёбра из скрытых: в скрытые %d, в видимые %d, смыт Лапидус %d", c.hid, c.vis, c.wash))
-- сколько скрытых состояний — чистое блуждание (мыло на полке, Лапидус далеко от мыла: ни одна клетка тела не соседствует с полкой)
local far, near = 0, 0
for i = 1, G.n do if L.status(ctx, i) == "hid" then
  local st = ctx.sts[i]; local adj = false
  for _, cb in ipairs(st.body) do local x, y = L.xy(ctx, cb); if y <= 5 then adj = true end end
  if adj then near = near + 1 else far = far + 1 end
end end
print(string.format("скрытых состояний: Лапидус внизу (ряды 6–7) %d, Лапидус поднялся к полке (ряд ≤ 5) %d", far, near))
L.free(ctx)
