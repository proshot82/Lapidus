-- pred.lua файл.lua "усл1" "усл2" ... — для каждого условия: живых / мёртвых (скрытых/видимых) состояний.
-- В условии: st, fx(tag), at(tag,x,y), L(x,y), P(tag) -> x,y
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local Q = {}
for q, p in ipairs(lvl.pieces) do if p.tag then Q[p.tag] = q end end
local conds = {}
for i = 2, #arg do conds[#conds + 1] = { arg[i], assert(load("return function(st, fx, at, L, P) return " .. arg[i] .. " end"))() } end
local function lost(st)
  for q, p in ipairs(lvl.pieces) do if p.movable and st.pos[q] == 0 then return true end end
  return def.visibleLoss and def.visibleLoss(lvl, st) or false
end
local cnt = {}
for i = 1, G.n do
  if G.flag[i] ~= 2 then
    local st = R.decode(lvl, G.keys[i])
    local function fx(t) return st.fixed[Q[t]] end
    local function at(t, x, y) return st.pos[Q[t]] == R.idx(lvl, x, y) end
    local function L(x, y) local c = R.idx(lvl, x, y); for _, b in ipairs(st.body) do if b == c then return true end end return false end
    local function P(t) if st.pos[Q[t]] == 0 then return 0, 0 end return R.xy(lvl, st.pos[Q[t]]) end
    for k, c in ipairs(conds) do
      if c[2](st, fx, at, L, P) then
        local a = cnt[k] or { 0, 0, 0 }; cnt[k] = a
        if good[i] == 1 then a[1] = a[1] + 1 elseif lost(st) then a[3] = a[3] + 1 else a[2] = a[2] + 1 end
      end
    end
  end
end
for k, c in ipairs(conds) do local a = cnt[k] or { 0, 0, 0 }; print(string.format("живых %7d  скрытых %7d  видимых %7d   %s", a[1], a[2], a[3], c[1])) end
SV.freeGraph(G); require("ffi").C.free(good)
