-- build/l7v_e/tail.lua файл.lua — для каждого класса ошибок (живое→скрытое): сколько разных конфигураций деталей в хвосте
-- и максимум смен конфигурации деталей на кратчайших путях внутри хвоста (0-1 BFS: ход без смены деталей стоит 0).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local lvl = R.compile(def)
V.POCKET = tonumber(os.getenv("POCKET") or 3)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local VL = V.compute(lvl, G, def, good)
local m = V.measure(G, good, VL.newbie)
local Q = {}; for q, p in ipairs(lvl.pieces) do if p.tag then Q[p.tag] = q end end
local function cfg(s) local t={} for _,q in ipairs({Q.elb,Q.plug}) do local x,y=R.xy(lvl,s.pos[q]); t[#t+1]=string.format("%d,%d%s",x,y,s.fixed[q] and "F" or "") end return table.concat(t," ") end
local groups = {}
for i = 1, G.n do if good[i] == 1 then
  for e = G.eStart.p[i-1], G.eStart.p[i]-1 do local j = G.edges.p[e]
    if m.hidden[j] then local k = cfg(VL.states[i]) .. " → " .. cfg(VL.states[j]); groups[k] = groups[k] or {}; table.insert(groups[k], j) end end end end
for k, js in pairs(groups) do
  local d, dq = {}, {}
  local deque = {}
  for _, j in ipairs(js) do d[j] = 0; deque[#deque+1] = j end
  local h = 1
  -- простая Дейкстра-подобная релаксация (веса 0/1), до сходимости
  local changed = true
  local set = {}
  while changed do changed = false
    for idx = 1, #deque do local u = deque[idx]
      for e = G.eStart.p[u-1], G.eStart.p[u]-1 do local v = G.edges.p[e]
        if m.hidden[v] then local w = (cfg(VL.states[u]) == cfg(VL.states[v])) and 0 or 1
          if d[v] == nil then deque[#deque+1] = v end
          if d[v] == nil or d[u] + w < d[v] then d[v] = d[u] + w; changed = true end end end end end
  local mx, cs = 0, {}
  for u, x in pairs(d) do if x > mx then mx = x end; cs[cfg(VL.states[u])] = true end
  local nc = 0; for _ in pairs(cs) do nc = nc + 1 end
  print(string.format("%-26s состояний %4d, конфигураций %2d, смен конфигурации до %d", k, #deque, nc, mx))
end
