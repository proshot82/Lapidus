-- build/l2v3/taut.lua — k6: после ошибки подсказки (висит на приманке) — сколько состояний можно перебрать, не сорвавшись,
-- и через сколько ходов впервые звучит отказ «натянут». Без ходов.
package.path = "./?.lua;" .. package.path
local R = require("core.rules"); local def = dofile(arg[1] or "build/l2e/k6.lua"); local lvl = R.compile(def)
arg = { arg[1] or "build/l2e/k6.lua" }
local real = print; print = function() end
local P = dofile("build/l2v3/probe.lua"); print = real
local sts, succ, live = P.sts, P.succ, P.live
local function onBait(st) if st.dead then return false end
  local piece = R.occupancy(st)
  for _, w in ipairs({ "head", "heel" }) do local q = R.endScrew(lvl, st, piece, w)
    if q and (lvl.pieces[q].tag == "under" or lvl.pieces[q].tag == "under2") then return lvl.pieces[q].tag end end end
local done = {}
for i = 1, #sts do if live[i] then for _, e in ipairs(succ[i]) do
  if def.hintError(lvl, sts[i], sts[e.j]) and not done[e.j] then done[e.j] = true
    local tag = onBait(sts[e.j])
    local seen, q, h = { [e.j] = 0 }, { e.j }, 1; local taut
    while h <= #q do local u = q[h]; h = h + 1
      for m = 1, 8 do local ns, why = R.move(lvl, sts[u], R.MOVES[m].which, R.MOVES[m].dir)
        if not ns and why == "taut" and not taut then taut = seen[u] end
        if ns and onBait(ns) == tag then local k = R.key(ns); local j = P.sts and nil
          for jj, s in ipairs(sts) do if R.key(s) == k then j = jj end end
          if j and not seen[j] then seen[j] = seen[u] + 1; q[#q + 1] = j end end end end
    local md = 0; for _, u in ipairs(q) do if seen[u] > md then md = seen[u] end end
    print(string.format("%-6s: висит на приманке — состояний %d, самое далёкое %d ходов; первый «натянут» через %s ходов", tag, #q, md, tostring(taut)))
  end end end end
