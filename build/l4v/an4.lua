-- build/l4v/an4.lua — (а) «всеведущая» обезьяна (все тупики видимы): сколько ворот «обезьяна» даёт сама длина;
-- (б) на сколько ходов в сторону от кратчайшего пути (по живым состояниям) лежит вход в каждый класс тупиков.
arg = { arg[1] or "build/l4v/k29_ruleid.lua", "4" }
dofile("build/l4v/an.lua")
local A = AN
local G, good, sts = A.G, A.good, A.sts
local V = require("tools.vislib")
local ES, E = G.eStart.p, G.edges.p
local omni = {}
for i = 1, G.n do if G.flag[i] ~= 2 then omni[i] = good[i] ~= 1 end end
local m = V.measure(G, good, omni)
print(string.format("всеведущая обезьяна (ходит только по живым): %.4f %% за 1000 ходов", m.smart))
local qc, qn, B, T = A.qc, A.qn, A.B, A.T
local cls = {
  К1 = function(st) return st.fixed[qc] and st.pos[qc] ~= B end,
  К2 = function(st) return st.fixed[qn] and st.pos[qn] ~= T end,
  К3 = function(st) return not st.fixed[qc] and not st.fixed[qn] and st.asm[qc] == st.asm[qn] end,
  К5 = function(st) return not st.fixed[qc] and not st.fixed[qn] and st.asm[qc] ~= st.asm[qn] end,
  r1 = function(st) return st.fixed[qn] and st.pos[qn] == T and not st.fixed[qc] end,
}
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
local d, q = {}, {}
for _, s in ipairs(path) do d[s] = 0; q[#q + 1] = s end
local h = 1
local first = {}
while h <= #q do
  local u = q[h]; h = h + 1
  for e = ES[u - 1], ES[u] - 1 do
    local v = E[e]
    if G.flag[v] ~= 2 and d[v] == nil then
      d[v] = d[u] + 1
      if good[v] == 1 then q[#q + 1] = v
      else
        for k, f in pairs(cls) do if f(sts[v]) and not first[k] then first[k] = { d[v], A.VL.newbie[v] and "видимо" or "скрыто" } end end
      end
    end
  end
end
for _, k in ipairs({ "К1", "К2", "К3", "К5", "r1" }) do
  local f = first[k]
  print(string.format("  %s: ближайший вход — %s ход(а) от кратчайшего пути (%s)", k, f and f[1] or "нет", f and f[2] or "-"))
end
