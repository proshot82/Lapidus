-- probe.lua файл.lua "lua-выражение по st/fx/at" — есть ли достижимые состояния с условием (для отладки раскладок).
-- В выражении доступны: st, fx(tag) — закреплена ли деталь, at(tag, x, y) — стоит ли деталь в клетке, L(x,y) — тело в клетке.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local Q = {}
for q, p in ipairs(lvl.pieces) do if p.tag then Q[p.tag] = q end end
local cond = assert(load("return function(st, fx, at, L) return " .. arg[2] .. " end"))()
local cnt, first = 0, nil
for i = 1, G.n do
  local st = R.decode(lvl, G.keys[i])
  local function fx(t) return st.fixed[Q[t]] end
  local function at(t, x, y) return st.pos[Q[t]] == R.idx(lvl, x, y) end
  local function L(x, y) local c = R.idx(lvl, x, y); for _, b in ipairs(st.body) do if b == c then return true end end return false end
  if cond(st, fx, at, L) then cnt = cnt + 1; if not first or G.depth[i] < G.depth[first] then first = i end end
end
print(string.format("состояний %d, с условием %d, ближайшее на глубине %s", G.n, cnt, first and G.depth[first] or "-"))
SV.freeGraph(G)
