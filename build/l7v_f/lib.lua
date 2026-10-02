-- build/l7v_f/lib.lua — метрики одним вызовом (мерка новичка/знатока по tools/vislib.lua), для вариантов уровня.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local ST = require("solver.strict")
local V = require("tools.vislib")
local M = {}
function M.metrics(def, opts)
  opts = opts or {}
  local lvl = R.compile(def)
  local errs = R.validate(lvl)
  if #errs > 0 then return { err = table.concat(errs, ";") } end
  local G = SV.explore(lvl, 3000000)
  if not G then return { err = "CAP" } end
  if not G.firstWin then local n = G.n; SV.freeGraph(G); return { solvable = false, n = n } end
  local good = SV.goodSet(G)
  V.POCKET = opts.pocket or 4
  local VL = V.compute(lvl, G, def, good)
  local m = V.measure(G, good, VL.newbie)
  local e = V.measure(G, good, VL.expert)
  local nwin = 0
  for i = 1, G.n do if G.flag[i] == 1 then nwin = nwin + 1 end end
  local r = { solvable = true, n = G.n, opt = m.opt, hid = m.hiddenPct, smart = m.smart, deep = m.maxDeep, dl = m.deepList,
    ehid = e.hiddenPct, edeep = e.maxDeep, nwin = nwin }
  SV.freeGraph(G); require("ffi").C.free(good)
  V.POCKET = 4
  if opts.strict then local sx = ST.check(def, 3000000); if sx then r.monkey, r.width = sx.monkey, sx.maxWidth end end
  if opts.abl then
    local a = SV.ablations(def, { cap = 3000000 })
    local s = {}
    for _, x in ipairs(a) do if x.solvable ~= false then s[#s+1] = x.name end end
    r.ablSolv = table.concat(s, ",")
  end
  return r
end
function M.fmt(r)
  if r.err then return "ERR " .. r.err end
  if not r.solvable then return "НЕРЕШАЕМ n=" .. r.n end
  return string.format("ходов %d n=%d win=%d | скрытых %.1f%% обез %.3f глуб %d [%s] | знаток %.1f%% глуб %d%s%s", r.opt, r.n, r.nwin, r.hid, r.smart, r.deep, r.dl,
    r.ehid, r.edeep, r.monkey and string.format(" | наобум %.3f шир %d", r.monkey, r.width) or "",
    r.ablSolv and (" | абл.РЕШАЕМЫ: [" .. r.ablSolv .. "]") or "")
end
return M
