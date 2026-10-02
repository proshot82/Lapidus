-- build/l6b/traps.lua файл.lua — какие правдоподобные ситуации живы/мертвы (по предикатам), судьба первых ходов.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local Q = {}
for q, p in ipairs(lvl.pieces) do if p.tag then Q[p.tag] = q end end
local function at(x, y) return R.idx(lvl, x, y) end
local src, stub
for q, p in ipairs(lvl.pieces) do if p.kind == "source" then src = q elseif p.kind == "stub" then stub = q end end
local function nbOf(q, d) if not q then return -1 end return lvl.nb[lvl.pieces[q].start][d] end
local preds = {
  { "муфта на отводе", function(st) return stub and st.fixed[Q.cpl] and st.pos[Q.cpl] == nbOf(stub, R.LEFT) end },
  { "муфта застряла справа от колонки", function(st) local x = R.xy(lvl, st.pos[Q.cpl]); return st.pos[Q.cpl] ~= 0 and x > 7 end },
  { "ниппель в колонке, Лапидус «задом наперёд»", function(st) return st.fixed[Q.nip] and st.fixed[Q.cpl] and not R.isWin(lvl, st) end },
  { "муфта на стояке, ниппель свободен", function(st) return st.fixed[Q.cpl] and st.pos[Q.cpl] == nbOf(src, R.RIGHT) and not st.fixed[Q.nip] end },
  { "ниппель в колонке, муфта свободна", function(st) return st.fixed[Q.nip] and not st.fixed[Q.cpl] end },
  { "обе детали на месте (не победа)", function(st) return st.fixed[Q.nip] and st.fixed[Q.cpl] and st.pos[Q.cpl] == nbOf(src, R.RIGHT) end },
  { "ниппель на полу/не на Лапидусе, не закреплён", function(st)
      if st.fixed[Q.nip] or st.pos[Q.nip] == 0 then return false end
      local below = lvl.nb[st.pos[Q.nip]][R.DOWN]
      for _, c in ipairs(st.body) do if c == below then return false end end
      return below ~= at(7,5) or st.pos[Q.cpl] ~= at(7,5) end },
}
local cnt = {}
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local st = R.decode(lvl, G.keys[i])
    for k, pr in ipairs(preds) do
      if pr[2](st) then cnt[k] = cnt[k] or { 0, 0 }; if good[i] == 1 then cnt[k][1] = cnt[k][1] + 1 else cnt[k][2] = cnt[k][2] + 1 end end
    end
  end
end
for k, pr in ipairs(preds) do local c = cnt[k] or { 0, 0 }; print(string.format("%-45s живых %6d  мёртвых %6d", pr[1], c[1], c[2])) end
local st0 = R.decode(lvl, G.keys[1])
for e = G.eStart.p[0], G.eStart.p[1] - 1 do
  local j = G.edges.p[e]
  print(string.format("  первый ход → %s (%s)", good[j] == 1 and "живое" or (G.flag[j] == 2 and "смыло" or "ТУПИК"), R.moveName(G.pmove[j])))
end
SV.freeGraph(G); require("ffi").C.free(good)
