-- build/l4v/an3.lua — разбиение класса К5 (порядок на полу) и сводная таблица разметок (без ходов).
arg = { arg[1] or "build/l4v/k29_ruleid.lua", "4" }
dofile("build/l4v/an.lua")
local R = require("core.rules")
local A = AN
local lvl, qc, qn, B, T = A.lvl, A.qc, A.qn, A.B, A.T
local function y(c) local _, yy = R.xy(lvl, c); return yy end
local function x(c) local xx = R.xy(lvl, c); return xx end
local K1 = function(st) return st.fixed[qc] and st.pos[qc] ~= B end
local K2 = function(st) return st.fixed[qn] and st.pos[qn] ~= T end
local K3 = function(st) return not st.fixed[qc] and not st.fixed[qn] and st.asm[qc] == st.asm[qn] end
local K5 = function(st) return not st.fixed[qc] and not st.fixed[qn] and st.asm[qc] ~= st.asm[qn] end
local K5b = function(st) return K5(st) and y(st.pos[qc]) >= 5 and y(st.pos[qn]) >= 5 and x(st.pos[qn]) > x(st.pos[qc]) end
local K5a = function(st) return K5(st) and not K5b(st) end
local cnt = { a = 0, b = 0 }
for i = 1, A.G.n do if A.G.flag[i] ~= 2 and A.good[i] ~= 1 and not A.VL.newbie[i] then
  if K5a(A.sts[i]) then cnt.a = cnt.a + 1 elseif K5b(A.sts[i]) then cnt.b = cnt.b + 1 end end end
print(string.format("К5a (муфта ещё не в коридоре / порядок не на полу): %d; К5b (обе на полу коридора, ниппель ближе к шахте): %d", cnt.a, cnt.b))
local rows = {
  { "К1+К2+К5b", function(s) return K1(s) or K2(s) or K5b(s) end },
  { "К1+К2+К3+К5b", function(s) return K1(s) or K2(s) or K3(s) or K5b(s) end },
  { "К3+К5b", function(s) return K3(s) or K5b(s) end },
}
for _, r in ipairs(rows) do
  local m = A.withExtra(r[2])
  print(string.format("  %-14s скрытых %.1f %% | обезьяна %.3f %% | глубина %d [%s]", r[1], m.hiddenPct, m.smart, m.maxDeep, m.deepList))
end
