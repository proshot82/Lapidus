-- Сравнение кв. 1–6 одной меркой: видимая потеря = Лапидус смыт или подвижная деталь смыта
-- (для кв. 6 — ещё и ниппель на полу). Скрытые тупики — остальные мёртвые состояния.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
for _, id in ipairs({ 1, 2, 3, 4, 5, 6 }) do
  local def = dofile(string.format("levels/%02d.lua", id))
  local lvl = R.compile(def)
  local G = SV.explore(lvl, 3000000)
  local good = SV.goodSet(G)
  local states = {}
  local function lost(st)
    for q, p in ipairs(lvl.pieces) do
      if p.movable then
        local c = st.pos[q]
        if c == 0 then return true end
        if id == 6 and not st.fixed[q] then
          local b = lvl.nb[c][R.DOWN]
          if b ~= 0 and lvl.cell[b] == R.WALL then return true end
        end
      end
    end
    return false
  end
  local live, vis, hid = 0, 0, 0
  for i = 1, G.n do
    if G.flag[i] ~= 2 then
      local st = R.decode(lvl, G.keys[i]); states[i] = st
      if good[i] == 1 then live = live + 1 elseif lost(st) then vis = vis + 1 else hid = hid + 1 end
    end
  end
  local opt = G.depth[G.firstWin]
  local T = 5 * opt
  local p, ok = { [1] = 1.0 }, 0
  for _ = 1, T do
    local np = {}
    for i, pr in pairs(p) do
      local cand = {}
      for e = G.eStart.p[i - 1], G.eStart.p[i] - 1 do
        local j = G.edges.p[e]
        if G.flag[j] == 1 then cand[#cand + 1] = j elseif G.flag[j] ~= 2 and not lost(states[j]) then cand[#cand + 1] = j end
      end
      if #cand == 0 then np[i] = (np[i] or 0) + pr else
        local share = pr / #cand
        for _, j in ipairs(cand) do if G.flag[j] == 1 then ok = ok + share else np[j] = (np[j] or 0) + share end end
      end
    end
    p = np
  end
  print(string.format("кв. %d: ходов %d; живых %d; видимых потерь %d; скрытых тупиков %d (%.0f %% от невидимо-проигранных+живых); умная обезьяна за 1000 ходов %.2f %%",
    id, opt, live, vis, hid, 100 * hid / math.max(1, hid + live), 100 * (1 - (1 - ok) ^ (1000 / T))))
  SV.freeGraph(G); require("ffi").C.free(good)
end
