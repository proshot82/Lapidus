-- build/l6c/a_f2plus/phases.lua файл.lua — поток умной обезьяны по фазам (по положению деталей), без ходов.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local Q = {}
for q, p in ipairs(lvl.pieces) do if p.tag then Q[p.tag] = q end end
local srcRow
for q, p in ipairs(lvl.pieces) do if p.source then srcRow = math.floor((p.start - 1) / lvl.W) + 1 end end
local cache = {}
local function S(i) cache[i] = cache[i] or R.decode(lvl, G.keys[i]); return cache[i] end
local function lost(s)
  for q, p in ipairs(lvl.pieces) do if p.movable and s.pos[q] == 0 then return true end end
  return def.visibleLoss and def.visibleLoss(lvl, s) or false
end
local function phase(s)
  local c, n = Q.cpl, Q.nip
  local cp = s.pos[c]; local crow = math.floor((cp - 1) / lvl.W) + 1
  local tag
  if s.fixed[c] then tag = "C:дома" elseif crow == srcRow then tag = "C:внизу" else tag = "C:наверху" end
  return tag .. (s.fixed[n] and "+N:в гнезде" or "")
end
local opt = G.depth[G.firstWin]
local T = 5 * opt
local p, ok = { [1] = 1.0 }, 0
local enter, died, winFrom = {}, {}, {}
local seenPhase = {}
for step = 1, T do
  local np = {}
  for i, pr in pairs(p) do
    local cand = {}
    for e = G.eStart.p[i - 1], G.eStart.p[i] - 1 do
      local j = G.edges.p[e]
      if G.flag[j] == 1 then cand[#cand + 1] = j elseif G.flag[j] ~= 2 and not lost(S(j)) then cand[#cand + 1] = j end
    end
    if #cand == 0 then np[i] = (np[i] or 0) + pr else
      local share = pr / #cand
      local fi = phase(S(i))
      for _, j in ipairs(cand) do
        if G.flag[j] == 1 then ok = ok + share; winFrom[fi] = (winFrom[fi] or 0) + share
        else
          local fj = phase(S(j))
          if good[i] == 1 and good[j] ~= 1 then died[fi .. " → " .. fj] = (died[fi .. " → " .. fj] or 0) + share end
          if fi ~= fj and good[j] == 1 then enter[fj] = (enter[fj] or 0) + share end
          np[j] = (np[j] or 0) + share
        end
      end
    end
  end
  p = np
end
local live, dead = {}, {}
for i, pr in pairs(p) do local f = phase(S(i)); if good[i] == 1 then live[f] = (live[f] or 0) + pr else dead[f] = (dead[f] or 0) + pr end end
print(string.format("за %d ходов выигрыш %.4f %%", T, 100 * ok))
local function dump(title, t) local l = {}; for k, v in pairs(t) do l[#l+1] = { k, v } end; table.sort(l, function(a, b) return a[2] > b[2] end); print(title); for _, x in ipairs(l) do print(string.format("  %7.3f %%  %s", 100 * x[2], x[1])) end end
dump("входы в фазу (живые):", enter)
dump("гибель (первый шаг в скрытый тупик):", died)
dump("в конце живы:", live)
SV.freeGraph(G); require("ffi").C.free(good)
