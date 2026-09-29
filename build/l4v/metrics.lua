-- build/l4v/metrics.lua — компактные метрики варианта уровня (без ходов): решаем, ходов, скрытых %, глубина,
-- кратчайших/ширина, состояний. M.run(def) → таблица.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local ST = require("solver.strict")
local V = require("tools.vislib")
local M = {}
function M.run(def, noStrict)
  local ok, lvl = pcall(R.compile, def)
  if not ok then return { err = tostring(lvl) } end
  local errs = R.validate(lvl)
  if #errs > 0 then return { err = errs[1] } end
  local G = SV.explore(lvl, 3000000)
  if not G then return { err = "cap" } end
  local good = SV.goodSet(G)
  local res = { n = G.n }
  if not G.firstWin then res.solvable = false
  else
    res.solvable = true
    local okv, VL = pcall(V.compute, lvl, G, def, good)
    if okv then
      local m = V.measure(G, good, VL.newbie)
      res.opt, res.hid, res.smart, res.deep, res.deepList = m.opt, m.hiddenPct, m.smart, m.maxDeep, m.deepList
      local ex = V.measure(G, good, VL.expert)
      res.exHid = ex.hiddenPct
    else res.opt = G.depth[G.firstWin]; res.verr = tostring(VL) end
    local wins = {}
    for i = 1, G.n do if G.flag[i] == 1 then
      local st = R.decode(lvl, G.keys[i]); local t = {}
      for q, p in ipairs(lvl.pieces) do if p.movable then t[#t+1] = st.pos[q] .. (st.fixed[q] and "F" or "") end end
      wins[table.concat(t, ",")] = true end end
    local nw = 0; for _ in pairs(wins) do nw = nw + 1 end
    res.winCfg = nw
    if not noStrict then
      local sx = ST.check(def, 3000000)
      if sx then res.shortest, res.width, res.monkey = sx.shortest, sx.maxWidth, sx.monkey end
    end
  end
  SV.freeGraph(G); require("ffi").C.free(good)
  return res
end
function M.fmt(r)
  if r.err then return "ошибка: " .. r.err end
  if not r.solvable then return string.format("НЕРЕШАЕМ (состояний %d)", r.n) end
  return string.format("ходов %d | сост %d | скрытых %.1f %% (знаток %.1f) | обезьяна %.3f | глубина %s [%s] | кратч %s шир %s | наобум %s | фин.конфиг %d%s",
    r.opt, r.n, r.hid or -1, r.exHid or -1, r.smart or -1, tostring(r.deep), tostring(r.deepList), tostring(r.shortest), tostring(r.width),
    r.monkey and string.format("%.3f", r.monkey) or "-", r.winCfg, r.verr and (" vlerr " .. r.verr) or "")
end
return M
