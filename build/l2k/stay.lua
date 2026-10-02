-- build/l2k/stay.lua файл — двери из живых состояний в скрытые тупики (мерка новичка) по всему графу:
-- для каждой «двери» (по конфигурации деталей после входа) — глубина скрытой области (самая длинная дорога без видимого
-- проигрыша) и расстояние от старта до входа. Порядок ходов не печатается.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local VL = V.compute(lvl, G, def, good)
local ES, E = G.eStart.p, G.edges.p
local hidden = {}
for i = 1, G.n do if G.flag[i] ~= 2 and good[i] ~= 1 and not VL.newbie[i] then hidden[i] = true end end
local function cfg(i)
  local st = R.decode(lvl, G.keys[i]); local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then
    if st.pos[q] == 0 then t[#t + 1] = (p.tag or "?") .. ":смыта" else
    local x, y = R.xy(lvl, st.pos[q]); t[#t + 1] = string.format("%s(%d,%d)%s", p.tag or "?", x, y, st.fixed[q] and "F" or "") end end end
  return table.concat(t, " ")
end
local function depth(j)
  local d, q, h, mx = { [j] = 0 }, { j }, 1, 0
  while h <= #q do
    local u = q[h]; h = h + 1
    for e = ES[u - 1], ES[u] - 1 do local v = E[e]; if hidden[v] and not d[v] then d[v] = d[u] + 1; if d[v] > mx then mx = d[v] end; q[#q + 1] = v end end
  end
  return mx
end
local doors = {}
for i = 1, G.n do if good[i] == 1 then
  for e = ES[i - 1], ES[i] - 1 do local j = E[e]
    if hidden[j] then
      local k = cfg(j)
      local d = doors[k] or { n = 0, mind = 1e9, maxdeep = 0 }
      d.n = d.n + 1; if G.depth[i] < d.mind then d.mind = G.depth[i] end
      local dp = depth(j); if dp > d.maxdeep then d.maxdeep = dp end
      doors[k] = d
    end
  end
end end
for k, d in pairs(doors) do print(string.format("вход в скрытое: %-28s рёбер %3d, от старта ≥ %2d ходов, глубина скрытой области до %d", k, d.n, d.mind, d.maxdeep)) end
