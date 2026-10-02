-- build/l10v/uniq.lua файл.lua — единственность: выигрышные состояния (конфигурация деталей, длина Лапидуса) и число
-- различных «планов» (порядков закрепления; сами порядки не печатаются) среди решений длиной ≤ opt+2 (план = порядок закрепления деталей и их места). Только метрики.
local L = dofile("build/l10v/lib.lua")
local S = L.load(arg[1])
local R = L.R
local cfgs = {}
for i = 1, S.n do if S.flag[i] == 1 then local s = S:st(i); local k = S:cfg(s) .. " | длина " .. #s.body; cfgs[k] = (cfgs[k] or 0) + 1 end end
local nc = 0
local tot = 0
for _, c in pairs(cfgs) do nc = nc + 1; tot = tot + c end
print(string.format("выигрышных состояний %d, различных конфигураций (детали + длина Лапидуса) %d", tot, nc))
-- планы: по рёбрам живых состояний; событие = деталь закрепилась; DFS по живым с глубиной ≤ opt+2 считать множество
-- последовательностей закреплений (без ходов)
local opt, dw = S:opt(), S:distWin()
local plans = {}
local function sig(s) local t = {}; for q, p in ipairs(S.lvl.pieces) do if p.movable and s.fixed[q] then t[#t+1] = p.tag end end; return t end
local memo = {}
local function walk(i, d, seq)
  if d + (dw[i] or 99) > opt + 2 then return end
  local key = i .. "|" .. d .. "|" .. seq
  if memo[key] then return end; memo[key] = true
  if S.flag[i] == 1 then plans[seq] = math.min(plans[seq] or 99, d) return end
  local f0 = #sig(S:st(i))
  for e = S.ES[i-1], S.ES[i]-1 do local j = S.E[e]
    if S:live(j) or S.flag[j] == 1 then
      local fj = sig(S:st(j))
      local ns = seq
      if #fj > f0 then ns = seq .. ">" .. table.concat(fj, "+") end
      walk(j, d + 1, ns) end end
end
walk(1, 0, "")
local n = 0
for _ in pairs(plans) do n = n + 1 end -- сами порядки не печатаются (это решение)
print("различных порядков закрепления среди решений ≤ opt+2: " .. n)
S:free()
