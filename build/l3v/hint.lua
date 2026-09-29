-- build/l3v/hint.lua [файл уровня] — ошибка из подсказки №1: «выбить нижнее мыло, пока верхнее НЕ на нём».
-- Проверяем со старта: какие ходы уводят в скрытое, глубина блуждания, через сколько ходов ошибка станет видимой,
-- если продолжать ложный план (верхнее мыло снять с полки влево / вправо).
local L = dofile("build/l3v/lib.lua")
local ctx = L.load(arg[1])
local G, R, lvl = ctx.G, ctx.R, ctx.lvl

local function hiddenDepth(j)
  local d, q, h, maxd, cnt = { [j] = 0 }, { j }, 1, 0, 1
  while h <= #q do
    local u = q[h]; h = h + 1
    for _, v in ipairs(L.edges(ctx, u)) do
      if L.status(ctx, v) == "hid" and d[v] == nil then d[v] = d[u] + 1; cnt = cnt + 1; if d[v] > maxd then maxd = d[v] end; q[#q + 1] = v end
    end
  end
  return maxd, cnt
end
-- кратчайшее число ходов из j до состояния, где верное (второе) мыло достигает данной конфигурации
local function distToCfg(j, pred)
  local d, q, h = { [j] = 0 }, { j }, 1
  while h <= #q do
    local u = q[h]; h = h + 1
    if G.flag[u] ~= 2 and pred(ctx.sts[u]) then return d[u] end
    for _, v in ipairs(L.edges(ctx, u)) do if d[v] == nil then d[v] = d[u] + 1; q[#q + 1] = v end end
  end
  return nil
end

print("старт: " .. L.cfg(ctx, ctx.sts[1]))
for _, j in ipairs(L.edges(ctx, 1)) do
  local s = L.status(ctx, j)
  local line = string.format("  ход → %-5s  %s", s, G.flag[j] == 2 and "смыт Лапидус" or L.cfg(ctx, ctx.sts[j]))
  if s == "hid" then
    local maxd, cnt = hiddenDepth(j)
    local dLeft = distToCfg(j, function(st) local c = st.pos[3]; if c == 0 then return false end; local x, y = R.xy(lvl, c); return x == 3 and y == 6 end)
    local dFloor = distToCfg(j, function(st) local c = st.pos[3]; if c == 0 then return false end; local x, y = R.xy(lvl, c); return y == 7 and x ~= 7 end)
    line = line .. string.format("   скрытая область: %d состояний, глубина %d; до мыла перед нишей (3,6): %s ходов; до мыла на полу у слива: %s ходов",
      cnt, maxd, tostring(dLeft), tostring(dFloor))
  end
  print(line)
end

-- обратная ошибка: верхнее мыло уже лежит на нижнем — что если теперь НЕ выбивать, а толкать нижнее влево?
print("\nсостояния «стопка» (верхнее на нижнем): исходы ходов")
local out = {}
for i = 1, G.n do
  if G.flag[i] ~= 2 and ctx.good[i] == 1 and L.cfg(ctx, ctx.sts[i]):match("^%(5,6%)/soap %(5,7%)/wall") then
    for _, j in ipairs(L.edges(ctx, i)) do
      local k = L.status(ctx, j) .. "  " .. (G.flag[j] == 2 and "смыт Лапидус" or L.cfg(ctx, ctx.sts[j]))
      out[k] = (out[k] or 0) + 1
    end
  end
end
local l = {}
for k, v in pairs(out) do l[#l + 1] = { k, v } end
table.sort(l, function(a, b) return a[2] > b[2] end)
for _, e in ipairs(l) do print(string.format("  %4d  %s", e[2], e[1])) end
L.free(ctx)
