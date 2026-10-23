-- кратчайшие решения: ширина по шагам; классы по последовательности конфигураций деталей; решения до opt+K
local L = dofile("build/l10v/lib.lua")
local S = L.load(arg[1] or "build/p6/fin/final.lua")
local K = tonumber(arg[2] or "4")
local dw, opt = S:distWin(), S:opt()
local function objs(i) local s = S:st(i); local t = {}
  for q, p in ipairs(S.lvl.pieces) do if p.movable then t[#t+1] = s.pos[q] .. (s.fixed[q] and "F" or "") end end
  return table.concat(t, ",") end
-- перечисление путей длины ≤ opt+K (простых по конфигурации) с подсчётом классов событий
local classes, count = {}, 0
local function dfs(i, d, seq, last, seen)
  if S.flag[i] == 1 then count = count + 1
    local k = table.concat(seq, ">"); local c = classes[k] or { n = 0, min = 99 }; classes[k] = c
    c.n = c.n + 1; if d < c.min then c.min = d end; return end
  for e = S.ES[i-1], S.ES[i]-1 do local j = S.E[e]
    if S.flag[j] ~= 2 and dw[j] and d + 1 + dw[j] <= opt + K and not seen[j] then
      seen[j] = true
      local o = objs(j)
      if o ~= last then seq[#seq+1] = o; dfs(j, d+1, seq, o, seen); seq[#seq] = nil else dfs(j, d+1, seq, last, seen) end
      seen[j] = nil
    end end
end
dfs(1, 0, {}, objs(1), { [1] = true })
local n = 0; for _ in pairs(classes) do n = n + 1 end
print(string.format("opt %d; путей ≤ opt+%d: %d; классов по событиям деталей: %d", opt, K, count, n))
local l = {}; for k, c in pairs(classes) do l[#l+1] = { k, c } end
table.sort(l, function(a, b) return a[2].min < b[2].min end)
for idx, x in ipairs(l) do local _, nev = x[1]:gsub(">", ""); print(string.format("  класс %d: мин. ходов %d, путей %d, событий %d", idx, x[2].min, x[2].n, nev + 1)) end
-- ширина кратчайших: на каждом шаге, сколько состояний и сколько разных конфигураций деталей
local sp = S:onShortest()
local W, O = {}, {}
for i in pairs(sp) do local d = S.G.depth[i]; W[d] = (W[d] or 0) + 1; O[d] = O[d] or {}; O[d][objs(i)] = true end
local a, b = {}, {}
for d = 0, opt do a[#a+1] = W[d] or 0; local c = 0; for _ in pairs(O[d] or {}) do c = c + 1 end; b[#b+1] = c end
print("состояний на шаг: " .. table.concat(a, " "))
print("конфигураций деталей на шаг: " .. table.concat(b, " "))
