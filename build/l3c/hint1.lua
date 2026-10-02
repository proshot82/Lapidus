-- build/l3c/hint1.lua файл.lua [rule=...] — проверка ошибки из подсказки №1 на графе состояний (без решений).
-- Подсказка: нижнее мыло — подставка; смыть его можно только из-под верхнего, ногами.
-- E1 «подставку смыли раньше»: ход смывает мыло, на котором НЕ лежит другое мыло.
-- E2 «подставку спасли от слива»: ход загоняет мыло в угол у стены (заклинило).
-- K  «выбили из-под верхнего» (правильный приём): ход смывает мыло, на котором лежит другое.
-- Для каждого: сколько таких ходов в графе, сколько состояний после них живы / мертвы (видимо / скрыто),
-- с какого хода кратчайшего пути ошибка достижима в один ход, и размер/глубина скрытой области после неё.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local rn = (arg[2] or "rule=own"):match("rule=(%w+)")
local rule = (rn == "own") and (def.lost or (def.washOk and def.visibleLoss)) or dofile("build/l3c/vis.lua").make(def.step or { { 7, 7 } }, false,
  ({ narrow = {}, d = { d = true }, e = { e = true }, wide = { d = true, e = true } })[rn])
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local S = {}
local function st(i) S[i] = S[i] or R.decode(lvl, G.keys[i]); return S[i] end
local soap = {}
for q, p in ipairs(lvl.pieces) do if p.porcelain then soap[#soap + 1] = q end end
local function kind(a, b)
  local A, B = st(a), st(b)
  for _, q in ipairs(soap) do
    if A.pos[q] ~= 0 and B.pos[q] == 0 then
      local up = lvl.nb[A.pos[q]][1]
      for _, r in ipairs(soap) do if r ~= q and A.pos[r] == up then return "K" end end
      return "E1"
    end
    if A.pos[q] ~= B.pos[q] and B.pos[q] ~= 0 then
      local c = B.pos[q]
      local W = lvl.W
      local x = (c - 1) % W + 1
      local below, left, right = lvl.nb[c][3], lvl.nb[c][4], lvl.nb[c][2]
      local isStep = false
      for _, sp in ipairs(def.step or { { 7, 7 } }) do if c == (sp[2] - 1) * W + sp[1] then isStep = true end end
      if not isStep and lvl.cell[below] == 1 and (lvl.cell[left] == 1 or lvl.cell[right] == 1) then
        -- угол: снизу стена и сбоку стена; толкнуть наружу нечем (с другой стороны стена)
        return "E2"
      end
    end
  end
  return nil
end
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
local onPath = {}
for k, id in ipairs(path) do onPath[id] = k - 1 end
local res = { E1 = { n = 0, live = 0, vis = 0, hid = 0, near = nil }, E2 = { n = 0, live = 0, vis = 0, hid = 0, near = nil }, K = { n = 0, live = 0, vis = 0, hid = 0, near = nil } }
local seen = {}
for i = 1, G.n do
  if G.flag[i] == 0 then
    for e = G.eStart.p[i - 1], G.eStart.p[i] - 1 do
      local j = G.edges.p[e]
      if G.flag[j] ~= 2 then
        local k = kind(i, j)
        if k then
          local r = res[k]; r.n = r.n + 1
          if not seen[k .. j] then
            seen[k .. j] = true
            if good[j] == 1 then r.live = r.live + 1 elseif rule(lvl, st(j)) then r.vis = r.vis + 1 else r.hid = r.hid + 1 end
          end
          if onPath[i] and (not r.near or onPath[i] < r.near) then r.near = onPath[i]; r.nearState = j end
        end
      end
    end
  end
end
local hidden = {}
for i = 1, G.n do if G.flag[i] == 0 and good[i] ~= 1 and not rule(lvl, st(i)) then hidden[i] = true end end
for _, k in ipairs({ "E1", "E2", "K" }) do
  local r = res[k]
  local extra = ""
  if r.nearState and hidden[r.nearState] then
    local d, q, h, maxd = { [r.nearState] = 0 }, { r.nearState }, 1, 0
    while h <= #q do local u = q[h]; h = h + 1
      for e = G.eStart.p[u - 1], G.eStart.p[u] - 1 do local v = G.edges.p[e]
        if hidden[v] and d[v] == nil then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; q[#q + 1] = v end end end
    extra = string.format("; с пути (ход %d) — в скрытую область %d состояний, глубина %d", r.near, #q, maxd)
  elseif r.near then extra = string.format("; с пути (ход %d) — %s", r.near, good[r.nearState] == 1 and "живое" or "видимый проигрыш") end
  print(string.format("[%s] %s: ходов %d; состояний после: живых %d, видимо проигранных %d, скрытых тупиков %d%s",
    rn, k, r.n, r.live, r.vis, r.hid, extra))
end
SV.freeGraph(G); require("ffi").C.free(good)
