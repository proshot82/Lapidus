-- build/l6c/a_f2plus/closeend.lua файл.lua — все переходы, где ниппель встал в гнездо: сколько живых после хода головой / ногами
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local nip
for q, p in ipairs(lvl.pieces) do if p.tag == "nip" then nip = q end end
local c = { head = { 0, 0 }, heel = { 0, 0 } }
for i = 1, G.n do
  if G.flag[i] == 0 then
    local st = R.decode(lvl, G.keys[i])
    if not st.fixed[nip] then
      for e = G.eStart.p[i - 1], G.eStart.p[i] - 1 do
        local j = G.edges.p[e]
        local ns = R.decode(lvl, G.keys[j])
        if ns.fixed[nip] then
          local which = (st.body[1] ~= ns.body[1]) and "heel" or "head"
          local t = c[which]; if good[j] == 1 then t[1] = t[1] + 1 else t[2] = t[2] + 1 end
        end
      end
    end
  end
end
print(string.format("ниппель вставлен головой: живых %d, мёртвых %d; ногами: живых %d, мёртвых %d", c.head[1], c.head[2], c.heel[1], c.heel[2]))
SV.freeGraph(G); require("ffi").C.free(good)
