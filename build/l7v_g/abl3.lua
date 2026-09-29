-- build/l7v_g/abl3.lua — узкие абляции скептика для F38 и «пара на весу» (обход или второе решение).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1] or "build/l7f/F38.lua")
local lvl = R.compile(def)
local W = lvl.W
local qe, qn
for k, p in ipairs(lvl.pieces) do if p.tag == "elb" then qe = k elseif p.tag == "nip" then qn = k end end
local function trace(st, ns)
  local k = R.key(ns)
  for m = 1, 8 do local mv = R.MOVES[m]; local tr = {}
    local s2 = R.move(lvl, st, mv.which, mv.dir, tr)
    if s2 and R.key(s2) == k then return tr end end
end
local function shifted(a, b, d) if #a ~= #b then return false end for i = 1, #a do if b[i] ~= a[i] + d then return false end end return true end
local tests = {
  { "нет свободной пары (угольник и ниппель свинчены, ниппель не прикручен)", function(_, st, ns)
      return ns.dead or not (ns.pos[qe] ~= 0 and ns.asm[qe] == ns.asm[qn] and not ns.fixed[qn]) end },
  { "ниппель прикручивается в устье только уже в паре с угольником", function(_, st, ns)
      if ns.dead then return true end
      if ns.fixed[qn] and not st.fixed[qn] then return ns.asm[qe] == ns.asm[qn] end
      return true end },
  { "ниппель прикручивается в устье только один (угольник не свинчен с ним)", function(_, st, ns)
      if ns.dead then return true end
      if ns.fixed[qn] and not st.fixed[qn] then return ns.asm[qe] ~= ns.asm[qn] end
      return true end },
  { "Лапидуса не поднимает струя (узко: подъём тела при устаканивании)", function(_, st, ns)
      if ns.dead then return true end
      local tr = trace(st, ns); if not tr then return true end
      for i = 2, #tr do if tr[i].kind == "settle" and shifted(tr[i-1].state.body, tr[i].state.body, -W) then return false end end
      return true end },
  { "угольник не поднимает струя (узко)", function(_, st, ns)
      if ns.dead then return true end
      local tr = trace(st, ns); if not tr then return true end
      for i = 2, #tr do local a, b = tr[i-1].state, tr[i].state
        if tr[i].kind == "settle" and a.pos[qe] ~= 0 and b.pos[qe] == a.pos[qe] - W then return false end end
      return true end },
  { "ниппель не поднимает струя (узко)", function(_, st, ns)
      if ns.dead then return true end
      local tr = trace(st, ns); if not tr then return true end
      for i = 2, #tr do local a, b = tr[i-1].state, tr[i].state
        if tr[i].kind == "settle" and a.pos[qn] ~= 0 and b.pos[qn] == a.pos[qn] - W then return false end end
      return true end },
  { "КОНТРОЛЬ: ниппель не заходит в левую половину верхней комнаты (x ≤ 5)", function(_, st, ns)
      if ns.dead then return true end local x, y = R.xy(lvl, ns.pos[qn]); return not (x <= 5 and y <= 3) end },
  { "КОНТРОЛЬ: Лапидус не заходит в левый низ (x ≤ 4, строки 5–7)", function(_, st, ns)
      if ns.dead then return true end
      for _, b in ipairs(ns.body) do local x, y = R.xy(lvl, b); if x <= 4 and y >= 5 then return false end end return true end },
}
local G0 = SV.explore(lvl, 3000000)
local good = SV.goodSet(G0)
local pairLive, pairAll = 0, 0
for i = 1, G0.n do if G0.flag[i] ~= 2 then local s = R.decode(lvl, G0.keys[i])
  if s.asm[qe] == s.asm[qn] and not s.fixed[qn] and s.pos[qe] ~= 0 then pairAll = pairAll + 1; if good[i] == 1 then pairLive = pairLive + 1 end end end end
print(string.format("свободная пара (угольник+ниппель свинчены, не прикручены): состояний %d, из них живых %d", pairAll, pairLive))
-- выигрышные конфигурации
for i = 1, G0.n do if G0.flag[i] == 1 then local s = R.decode(lvl, G0.keys[i]); print("выигрыш: глубина " .. G0.depth[i] .. ", длина Лапидуса " .. #s.body) end end
SV.freeGraph(G0); require("ffi").C.free(good)
for _, t in ipairs(tests) do
  local G = SV.explore(lvl, 3000000, t[2])
  if G and G.firstWin then print(string.format("РЕШАЕМ за %d (состояний %d): %s", G.depth[G.firstWin], G.n, t[1]))
  else print(string.format("нерешаем (состояний %d): %s", G and G.n or -1, t[1])) end
  if G then SV.freeGraph(G) end
end
