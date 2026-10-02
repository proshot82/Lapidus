-- build/l10a/lib10.lua — метрики одним вызовом для вариантов уровня кв. 10 (замуровка, мутации): мерка новичка по
-- tools/vislib.lua, двери с кратчайшего пути по половинам, абляции (по желанию). Ходы не печатаются.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local ST = require("solver.strict")
local V = require("tools.vislib")
local M = {}
function M.metrics(def, opts)
  opts = opts or {}
  local ok, lvl = pcall(R.compile, def)
  if not ok then return { err = tostring(lvl) } end
  local errs = R.validate(lvl)
  if #errs > 0 then return { err = table.concat(errs, ";") } end
  local G = SV.explore(lvl, opts.cap or 3000000)
  if not G then return { err = "CAP" } end
  if not G.firstWin then local n = G.n; SV.freeGraph(G); return { solvable = false, n = n } end
  local good = SV.goodSet(G)
  local VL = V.compute(lvl, G, def, good)
  local m = V.measure(G, good, VL.newbie)
  local ES, E, flag = G.eStart.p, G.edges.p, G.flag
  -- двери с одного кратчайшего пути по половинам
  local path = m.path
  local halves = { 0, 0 }
  for k = 1, #path - 1 do
    local s, c = path[k], 0
    for e = ES[s-1], ES[s]-1 do if m.hidden[E[e]] then c = c + 1 end end
    if c > 0 then local h = (k-1) < (#path-1)/2 and 1 or 2; halves[h] = halves[h] + 1 end
  end
  local nwin, wcfg = 0, {}
  for i = 1, G.n do if flag[i] == 1 then nwin = nwin + 1; local st = R.decode(lvl, G.keys[i]); local t = {}; for q = 1, #st.pos do t[#t+1] = st.pos[q] .. (st.fixed[q] and "f" or "") end; wcfg[table.concat(t, ",")] = true end end
  local ncfg = 0; for _ in pairs(wcfg) do ncfg = ncfg + 1 end
  local r = { solvable = true, n = G.n, opt = m.opt, hid = m.hiddenPct, smart = m.smart, deep = m.maxDeep, d1 = halves[1], d2 = halves[2], nwin = nwin, ncfg = ncfg, unstable = G.unstable }
  SV.freeGraph(G); require("ffi").C.free(good)
  if opts.strict then local sx = ST.check(def, 3000000); if sx then r.monkey, r.width, r.shortest = sx.monkey, sx.maxWidth, sx.shortest end end
  if opts.abl then
    local s = {}
    for _, ab in ipairs(def.ablations or {}) do
      local d2 = SV.deepcopy(def); d2.ablations = nil; d2.controls = nil
      SV.applyAblation(d2, ab)
      local ok2, lvl2 = pcall(R.compile, d2)
      local solv = false
      if ok2 and #R.validate(lvl2) == 0 then
        local G2 = SV.explore(lvl2, 3000000, ab.filter)
        solv = G2 and (G2.firstWin ~= nil) or false
        if G2 then SV.freeGraph(G2) end
      end
      if solv then s[#s+1] = ab.name end
    end
    r.ablSolv = table.concat(s, ", ")
  end
  return r
end
function M.fmt(r)
  if r.err then return "ERR " .. r.err end
  if not r.solvable then return "НЕРЕШАЕМ n=" .. r.n end
  return string.format("ходов %d n=%d конф %d | скрытых %.1f%% обез %.3f глуб %d | двери %d/%d%s%s%s", r.opt, r.n, r.ncfg, r.hid, r.smart, r.deep, r.d1, r.d2,
    r.monkey and string.format(" | наобум %.3f кратч %d шир %d", r.monkey, r.shortest, r.width) or "",
    r.ablSolv and (r.ablSolv ~= "" and (" | абл.РЕШАЕМЫ: [" .. r.ablSolv .. "]") or " | абл. все нерешаемы") or "",
    r.unstable > 0 and (" | НЕУСТОЙЧИВЫХ " .. r.unstable) or "")
end
return M
