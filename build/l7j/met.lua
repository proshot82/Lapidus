-- build/l7j/met.lua — метрики ворот одним вызовом (для мутатора): ходов, ширина, прогулка, скрытые, обезьяна, глубина, двери.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local M = {}
function M.eval(def, cap)
  local okc, lvl = pcall(R.compile, def)
  if not okc then return { err = "compile" } end
  local errs, warns = R.validate(lvl)
  if #errs > 0 then return { err = "validate" } end
  if #warns > 0 then return { err = "notrest" } end
  local G = SV.explore(lvl, cap or 400000)
  if not G then return { err = "cap" } end
  if not G.firstWin then local n = G.n; SV.freeGraph(G); return { err = "unsolvable", n = n } end
  local np = #lvl.pieces
  local cfg, nc = {}, 0
  for i = 1, G.n do if G.flag[i] == 1 then local st = R.decode(lvl, G.keys[i]); local kk = {}; for q = 1, np do kk[#kk + 1] = st.pos[q] .. (st.fixed[q] and "f" or "") end; local k = table.concat(kk, ","); if not cfg[k] then cfg[k] = true; nc = nc + 1 end end end
  local win = R.decode(lvl, G.keys[G.firstWin])
  local res = { n = G.n, opt = G.depth[G.firstWin], ncfg = nc, win = win, lvl = lvl }
  if M.pre and not M.pre(res, def) then SV.freeGraph(G); res.err = "pre"; return res end
  local opt = res.opt
  local ES, E = G.eStart.p, G.edges.p
  -- ширина коридора кратчайших (как solver/strict.lua)
  local on = {}
  for i = G.n, 1, -1 do
    if G.flag[i] == 1 and G.depth[i] == opt then on[i] = true
    elseif G.flag[i] == 0 and G.depth[i] < opt then
      for e = ES[i - 1], ES[i] - 1 do local j = E[e]; if on[j] and G.depth[j] == G.depth[i] + 1 then on[i] = true break end end
    end
  end
  local wd, maxw = {}, 1
  for i = 1, G.n do if on[i] then wd[G.depth[i]] = (wd[G.depth[i]] or 0) + 1; if wd[G.depth[i]] > maxw then maxw = wd[G.depth[i]] end end end
  res.width = maxw
  local good = SV.goodSet(G)
  local VL = V.compute(lvl, G, def, good)
  local m = V.measure(G, good, VL.newbie)
  res.hid, res.smart, res.deep = m.hiddenPct, m.smart, m.maxDeep
  local h1, h2 = 0, 0
  for k = 1, #m.path - 1 do
    local s = m.path[k]
    for e = ES[s - 1], ES[s] - 1 do if m.hidden[E[e]] then res.doorSteps = (res.doorSteps or "") .. (k - 1) .. " "; if (k - 1) < (#m.path - 1) / 2 then h1 = h1 + 1 else h2 = h2 + 1 end break end end
  end
  res.d1, res.d2 = h1, h2
  local streak, maxs, ev, stepOn = 0, 0, 0, 0
  local prev = R.decode(lvl, G.keys[m.path[1]])
  for k = 2, #m.path do
    local cur = R.decode(lvl, G.keys[m.path[k]])
    local ch = false
    for q = 1, np do if cur.pos[q] ~= prev.pos[q] or cur.fixed[q] ~= prev.fixed[q] then ch = true end end
    if ch then ev = ev + 1; streak = 0 else streak = streak + 1; if streak > maxs then maxs = streak end end
    local piece = R.occupancy(cur)
    for _, b in ipairs(cur.body) do
      local under = lvl.nb[b][R.DOWN]; local q = piece[under]
      if q and lvl.pieces[q].movable and not cur.fixed[q] then stepOn = stepOn + 1 break end
    end
    prev = cur
  end
  res.walk, res.events, res.stepOn = maxs, ev, stepOn
  require("ffi").C.free(good)
  SV.freeGraph(G)
  return res
end
return M
