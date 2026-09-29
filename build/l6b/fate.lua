-- build/l6b/fate.lua файл.lua — куда уходит «умная обезьяна» за одну попытку (5×опт ходов):
-- доля вероятности в выигрыше / живых / скрытых тупиках по конфигурациям деталей.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local VL = V.compute(lvl, G, def, good) -- общая линейка (мерка новичка)
local states = {}
local function st(i) states[i] = states[i] or R.decode(lvl, G.keys[i]); return states[i] end
local function lost(s)
  -- def.washOk: смытая деталь сама по себе не проигрыш (в кв. 3 одно мыло уходит в слив по замыслу) — решает def.visibleLoss
  if not def.washOk then
    for q, p in ipairs(lvl.pieces) do if p.movable and s.pos[q] == 0 then return true end end
  end
  return def.visibleLoss and def.visibleLoss(lvl, s) or false
end
local function cfg(s)
  local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then
    local x, y = R.xy(lvl, s.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag, x, y, s.fixed[q] and "F" or "") end end
  local b = s.body; local hx, hy = R.xy(lvl, b[#b]); local fx, fy = R.xy(lvl, b[1])
  return table.concat(t, " ")
end
local opt = G.depth[G.firstWin]
local T = tonumber(arg[2] or 5 * opt)
local p, ok = { [1] = 1.0 }, 0
local firstDead = {}
for step = 1, T do
  local np = {}
  for i, pr in pairs(p) do
    local cand = {}
    for e = G.eStart.p[i - 1], G.eStart.p[i] - 1 do
      local j = G.edges.p[e]
      if G.flag[j] == 1 then cand[#cand + 1] = j elseif G.flag[j] ~= 2 and not VL.newbie[j] then cand[#cand + 1] = j end
    end
    if #cand == 0 then np[i] = (np[i] or 0) + pr else
      local share = pr / #cand
      for _, j in ipairs(cand) do
        if G.flag[j] == 1 then ok = ok + share
        elseif good[j] == 1 and good[i] == 1 and cfg(st(i)) ~= cfg(st(j)) then
          local k = "ЖИВОЙ сдвиг: " .. cfg(st(i)) .. "  →  " .. cfg(st(j)); firstDead[k] = (firstDead[k] or 0) + share
          np[j] = (np[j] or 0) + share
        elseif good[j] ~= 1 and good[i] == 1 then -- первый шаг в скрытый тупик: запомним, откуда
          local k = cfg(st(i)) .. "  →  " .. cfg(st(j)); firstDead[k] = (firstDead[k] or 0) + share
          np[j] = (np[j] or 0) + share
        else np[j] = (np[j] or 0) + share end
      end
    end
  end
  p = np
end
local liveP, deadP = 0, 0
for i, pr in pairs(p) do if good[i] == 1 then liveP = liveP + pr else deadP = deadP + pr end end
print(string.format("за %d ходов: выигрыш %.4f %%, ещё живы %.1f %%, в тупиках %.1f %%", T, 100 * ok, 100 * liveP, 100 * deadP))
local l = {}
for k, v in pairs(firstDead) do l[#l+1] = { k, v } end
table.sort(l, function(a, b) return a[2] > b[2] end)
for i = 1, math.min(8, #l) do print(string.format("  %5.1f %%  %s", 100 * l[i][2], l[i][1])) end
SV.freeGraph(G); require("ffi").C.free(good)
