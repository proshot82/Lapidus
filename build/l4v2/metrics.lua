-- build/l4v2/metrics.lua — метрики варианта уровня (без ходов): ходы, состояния, скрытые (автор / L видим / L+P видимы),
-- число кратчайших и ширина, глубина. M.run(def, withAbl) -> таблица; M.fmt(t) -> строка.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local M = {}
function M.run(def, withAbl)
  local lvl = R.compile(def)
  local errs = R.validate(lvl)
  if #errs > 0 then return { err = table.concat(errs, ";") } end
  local G = SV.explore(lvl, 3000000)
  if not G then return { err = "cap" } end
  if not G.firstWin then local n = G.n; SV.freeGraph(G); return { unsolvable = true, n = n } end
  local good = SV.goodSet(G)
  local VL = V.compute(lvl, G, def, good)
  local sts = VL.states
  local qc, qn
  for q, p in ipairs(lvl.pieces) do if p.what == "coupling" then qc = q elseif p.what == "nipple" then qn = q end end
  local W = lvl.W
  local function isL(st) if not qn or st.fixed[qn] or (qc and st.asm[qc] == st.asm[qn]) then return false end
    local x, y = R.xy(lvl, st.pos[qn]); return y == 6 and x <= 6 end
  local function isP(st) return qc and qn and st.asm[qc] == st.asm[qn] and not st.fixed[qc] end
  local L1, L2 = {}, {}
  for i = 1, G.n do if G.flag[i] ~= 2 then
    L1[i] = VL.newbie[i] or (good[i] ~= 1 and isL(sts[i]))
    L2[i] = L1[i] or (good[i] ~= 1 and isP(sts[i]))
  end end
  local a = V.measure(G, good, VL.newbie)
  local b = V.measure(G, good, L1)
  local c = V.measure(G, good, L2)
  local ex = V.measure(G, good, VL.expert)
  -- кратчайшие: число и ширина
  local opt = G.depth[G.firstWin]
  local ES, E, flag = G.eStart.p, G.edges.p, G.flag
  local cnt = { [1] = 1 }
  for i = 1, G.n do local ci = cnt[i]
    if ci and flag[i] == 0 then for e = ES[i - 1], ES[i] - 1 do local j = E[e]
      if G.depth[j] == G.depth[i] + 1 then cnt[j] = (cnt[j] or 0) + ci end end end end
  local on, total = {}, 0
  for i = 1, G.n do if flag[i] == 1 and G.depth[i] == opt then on[i] = true; total = total + (cnt[i] or 0) end end
  for i = G.n, 1, -1 do if not on[i] and flag[i] == 0 and G.depth[i] < opt then
    for e = ES[i - 1], ES[i] - 1 do local j = E[e]; if on[j] and G.depth[j] == G.depth[i] + 1 then on[i] = true break end end end end
  local wd, maxw = {}, 1
  for i = 1, G.n do if on[i] then wd[G.depth[i]] = (wd[G.depth[i]] or 0) + 1; if wd[G.depth[i]] > maxw then maxw = wd[G.depth[i]] end end end
  local nwin = 0; for i = 1, G.n do if flag[i] == 1 then nwin = nwin + 1 end end
  local res = { opt = opt, n = G.n, live = a.live, hidA = a.hiddenPct, hidL = b.hiddenPct, hidLP = c.hiddenPct, hidEx = ex.hiddenPct,
    deep = a.maxDeep, deepList = a.deepList, deepLP = c.maxDeep, smart = a.smart, short = total, width = maxw, nwin = nwin }
  SV.freeGraph(G); require("ffi").C.free(good)
  if withAbl then
    local ab = {}
    for _, x in ipairs(SV.ablations(def, { cap = 3000000 })) do ab[#ab + 1] = (x.solvable == false) and "н" or "Р" end
    res.abl = table.concat(ab)
  end
  return res
end
function M.fmt(t)
  if t.err then return "ошибка " .. t.err end
  if t.unsolvable then return string.format("НЕРЕШАЕМ (состояний %d)", t.n) end
  return string.format("ходов %d | сост %d | живых %d | скрытых автор %.1f %% / L видим %.1f %% / L+P %.1f %% / знаток %.1f %% | глуб %d [%s] (L+P: %d) | обезьяна %.3f | кратч %d шир %d | выигр.сост %d%s",
    t.opt, t.n, t.live, t.hidA, t.hidL, t.hidLP, t.hidEx, t.deep, t.deepList, t.deepLP, t.smart, t.short, t.width, t.nwin, t.abl and (" | абл " .. t.abl) or "")
end
return M
