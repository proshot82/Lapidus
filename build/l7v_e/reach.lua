-- build/l7v_e/reach.lua файл.lua класс — куда вообще могут прийти детали из скрытых тупиков класса
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local VL = V.compute(lvl, G, def, good)
local Q = {}; for q, p in ipairs(lvl.pieces) do if p.tag then Q[p.tag] = q end end
local E, P = Q.elb, Q.plug
local function xy(c) if c == 0 then return 0, 0 end return R.xy(lvl, c) end
local cls = arg[2]
local pred = ({
  K3 = function(s) local x1,y1=xy(s.pos[E]); local x2,y2=xy(s.pos[P]); return x1==5 and x2==5 and y1<=3 and y2<=3 end,
  K2 = function(s) local x,y = xy(s.pos[E]); return y==6 and x<=4 and not s.fixed[P] end,
  K1 = function(s) return s.fixed[E] and not s.fixed[P] end,
})[cls]
local function cfg(s) local t={} for _,q in ipairs({E,P}) do local x,y=xy(s.pos[q]); t[#t+1]=string.format("%d,%d%s",x,y,s.fixed[q] and "F" or "") end return table.concat(t," ") end
local seen, q = {}, {}
for i=1,G.n do if G.flag[i]~=2 and good[i]~=1 and not VL.newbie[i] and pred(VL.states[i]) then seen[i]=true; q[#q+1]=i end end
local h=1
while h<=#q do local u=q[h]; h=h+1; for e=G.eStart.p[u-1],G.eStart.p[u]-1 do local v=G.edges.p[e]; if G.flag[v]~=2 and not seen[v] then seen[v]=true; q[#q+1]=v end end end
local agg={}
for i in pairs(seen) do local k=cfg(VL.states[i]); local a=agg[k] or {0,0}; agg[k]=a; if VL.newbie[i] then a[2]=a[2]+1 else a[1]=a[1]+1 end end
for k,a in pairs(agg) do print(string.format("%-20s скрытых %5d видимых %5d", k, a[1], a[2])) end
