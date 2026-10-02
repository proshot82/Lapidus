-- build/l4v/an5.lua — глубина скрытой области от входов (из живого состояния) в каждый класс (без ходов).
arg = { arg[1] or "build/l4v/k29_ruleid.lua", "4" }
dofile("build/l4v/an.lua")
local A = AN
local G, good, sts, VL = A.G, A.good, A.sts, A.VL
local ES, E = G.eStart.p, G.edges.p
local qc, qn, B, T = A.qc, A.qn, A.B, A.T
local cls = {
  { "К1", function(st) return st.fixed[qc] and st.pos[qc] ~= B end },
  { "К2", function(st) return st.fixed[qn] and st.pos[qn] ~= T end },
  { "К3", function(st) return not st.fixed[qc] and not st.fixed[qn] and st.asm[qc] == st.asm[qn] end },
  { "К5", function(st) return not st.fixed[qc] and not st.fixed[qn] and st.asm[qc] ~= st.asm[qn] end },
}
local hidden = {}
for i = 1, G.n do if G.flag[i] ~= 2 and good[i] ~= 1 and not VL.newbie[i] then hidden[i] = true end end
local function depthFrom(j)
  local d, q, h, maxd = { [j] = 0 }, { j }, 1, 0
  while h <= #q do local u = q[h]; h = h + 1
    for e = ES[u - 1], ES[u] - 1 do local v = E[e]
      if hidden[v] and d[v] == nil then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; q[#q + 1] = v end end end
  return maxd
end
for _, c in ipairs(cls) do
  local nEnt, maxD, sumD, seen = 0, 0, 0, {}
  for i = 1, G.n do if good[i] == 1 and G.flag[i] == 0 then
    for e = ES[i - 1], ES[i] - 1 do local j = E[e]
      if hidden[j] and not seen[j] and c[2](sts[j]) then seen[j] = true; nEnt = nEnt + 1; local d = depthFrom(j); sumD = sumD + d; if d > maxD then maxD = d end end end end end
  print(string.format("%s: входов из живого %d, глубина скрытой области от входа: макс %d, средняя %.1f", c[1], nEnt, maxD, nEnt > 0 and sumD / nEnt or 0))
end
