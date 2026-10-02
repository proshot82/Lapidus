-- build/l9j/eval.lua — быстрые ворота для генератора/ручных кандидатов кв. 9 (модуль).
-- E.eval(def, cap) -> nil | {opt, n, hidPct, smart, maxDeep, doors1, doors2, doorList, width?}
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local E = {}
function E.eval(def, cap, full)
  local lvl = R.compile(def)
  local errs = R.validate(lvl)
  if #errs > 0 then return nil, "invalid" end
  local okS = pcall(R.newState, lvl)
  if not okS then return nil, "settle" end
  local G = SV.explore(lvl, cap or 400000, def._filter)
  if not G then return nil, "cap" end
  if not G.firstWin then local n = G.n; SV.freeGraph(G); return nil, "unsolvable", n end
  local good = SV.goodSet(G)
  local res = { opt = G.depth[G.firstWin], n = G.n }
  local win = R.decode(lvl, G.keys[G.firstWin])
  res.win = win
  local nwin = 0
  for i = 1, G.n do if G.flag[i] == 1 then nwin = nwin + 1 end end
  res.nwin = nwin
  if full ~= false then
    local VL = V.compute(lvl, G, def, good)
    local hidden, live, hid = {}, 0, 0
    for i = 1, G.n do
      if G.flag[i] ~= 2 then
        if good[i] == 1 then live = live + 1 elseif not VL.newbie[i] then hid = hid + 1; hidden[i] = true end
      end
    end
    res.hidPct = 100 * hid / math.max(1, hid + live)
    local opt = res.opt
    local T = 5 * opt
    local p, ok = { [1] = 1.0 }, 0
    for _ = 1, T do
      local np = {}
      for i, pr in pairs(p) do
        local cand = {}
        for e = G.eStart.p[i - 1], G.eStart.p[i] - 1 do
          local j = G.edges.p[e]
          if G.flag[j] == 1 then cand[#cand + 1] = j elseif G.flag[j] ~= 2 and not VL.newbie[j] then cand[#cand + 1] = j end
        end
        if #cand == 0 then np[i] = (np[i] or 0) + pr else
          local share = pr / #cand
          for _, j in ipairs(cand) do if G.flag[j] == 1 then ok = ok + share else np[j] = (np[j] or 0) + share end end
        end
      end
      p = np
    end
    res.smart = 100 * (1 - (1 - ok) ^ (1000 / T))
    local path, x = {}, G.firstWin
    while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
    table.insert(path, 1, 1)
    local memo = {}
    local function depthFrom(j)
      if memo[j] then return memo[j] end
      local d, q, h, maxd = { [j] = 0 }, { j }, 1, 0
      while h <= #q do
        local u = q[h]; h = h + 1
        for e = G.eStart.p[u - 1], G.eStart.p[u] - 1 do
          local v = G.edges.p[e]
          if hidden[v] and d[v] == nil then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; q[#q + 1] = v end
        end
      end
      memo[j] = maxd
      return maxd
    end
    local halves, list, maxDeep = { 0, 0 }, {}, 0
    local deepHalves = { 0, 0 }
    for k = 1, #path - 1 do
      local s, c, dmax = path[k], 0, -1
      for e = G.eStart.p[s - 1], G.eStart.p[s] - 1 do
        local j = G.edges.p[e]
        if hidden[j] then c = c + 1; local d = depthFrom(j); if d > dmax then dmax = d end end
      end
      if c > 0 then
        local h = (k - 1) < (#path - 1) / 2 and 1 or 2
        halves[h] = halves[h] + 1
        if dmax >= 8 then deepHalves[h] = deepHalves[h] + 1 end
        if dmax > maxDeep then maxDeep = dmax end
        list[#list + 1] = (k - 1) .. ":" .. dmax
      end
    end
    res.doors1, res.doors2, res.deep1, res.deep2 = halves[1], halves[2], deepHalves[1], deepHalves[2]
    res.doorList = table.concat(list, " ")
    res.maxDeep = maxDeep
    local function objs(i) local st = R.decode(lvl, G.keys[i]); local t = {}; for q = 1, #st.pos do t[#t+1] = st.pos[q] .. (st.fixed[q] and "f" or "") end; return table.concat(t, ",") end
    local streak, ms, ev = 0, 0, 0
    for i = 1, #path - 1 do
      if objs(path[i]) ~= objs(path[i + 1]) then ev = ev + 1; streak = 0 else streak = streak + 1; if streak > ms then ms = streak end end
    end
    res.walk, res.events = ms, ev
  end
  SV.freeGraph(G); require("ffi").C.free(good)
  return res
end
return E
