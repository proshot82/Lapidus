-- build/l4v3/sp.lua файл [extra] — ширина коридора кратчайших: по шагам (состояний / раскладок деталей),
-- различные «планы» = последовательности закреплений деталей (порядок событий) среди всех кратчайших и решений opt+extra.
-- Печатает только метки деталей и число решений, без ходов.
package.path = "./?.lua;" .. package.path
local L = dofile("build/l4v3/lib.lua")
local A = L.load(arg[1])
local G, sts = A.G, A.sts
local ES, E = G.eStart.p, G.edges.p
local by, cfgs = {}, {}
for i in pairs(A.onSP) do local d = G.depth[i]
  by[d] = (by[d] or 0) + 1; cfgs[d] = cfgs[d] or {}; cfgs[d][L.cfg(A, sts[i])] = true end
local t = {}
for d = 0, A.opt do local n = 0; for _ in pairs(cfgs[d] or {}) do n = n + 1 end; t[#t + 1] = (by[d] or 0) .. "/" .. n end
print("по шагам (состояний на кратчайших / раскладок деталей): " .. table.concat(t, " "))
-- планы: для решений длины <= opt+extra — последовательность событий «деталь закреплена» и «деталь сменила спуск»
local extra = tonumber(arg[2] or "0")
local lim = A.opt + extra
local function fixedSet(st) local s = ""; for _, tag in ipairs({ "cpl", "nip", "elb" }) do if st.fixed[A.Q[tag]] then s = s .. tag:sub(1, 1) end end return s end
-- DFS по рёбрам с отсечением toWin: подсчёт решений по последовательности закреплений
local plans = {}
local total = 0
local function rec(i, len, seq, last)
  if G.flag[i] == 1 then plans[seq] = (plans[seq] or 0) + 1; total = total + 1; return end
  if not A.toWin[i] or len + A.toWin[i] > lim then return end
  for e = ES[i - 1], ES[i] - 1 do local j = E[e]
    if G.flag[j] ~= 2 and A.toWin[j] and len + 1 + A.toWin[j] <= lim then
      local f = fixedSet(sts[j])
      rec(j, len + 1, f ~= last and (seq .. ">" .. f) or seq, f)
    end
  end
end
rec(1, 0, "", fixedSet(sts[1]))
print(string.format("решений длины ≤ opt+%d: %d; разных последовательностей закреплений: ", extra, total))
for k, v in pairs(plans) do print("   " .. k, v) end
-- раскладка при появлении первого закрепления: какая деталь спускается первой куда (по классу маршрута)
