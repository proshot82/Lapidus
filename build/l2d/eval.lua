-- build/l2d/eval.lua — ворота §7 функцией (та же формула, что build/l6b/check.lua, общая линейка tools/vislib.lua).
-- local EV = dofile("build/l2d/eval.lua"); local r = EV.eval(def) → r.line, r.fails, r.* (числа). Решений не печатает.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local ST = require("solver.strict")
local V = require("tools.vislib")
local M = {}

function M.eval(def, opts)
  opts = opts or {}
  local ok, lvl = pcall(R.compile, def)
  if not ok then return { line = "COMPILE: " .. tostring(lvl), fails = { "compile" } } end
  local errs = R.validate(lvl)
  if #errs > 0 then return { line = "ОШИБКИ: " .. table.concat(errs, "; "), fails = { "invalid" } } end
  local G = SV.explore(lvl, opts.cap or 3000000)
  if not G then return { line = "CAP", fails = { "cap" } } end
  if not G.firstWin then local n = G.n; SV.freeGraph(G); return { line = "НЕРЕШАЕМ (" .. n .. ")", fails = { "unsolvable" }, unsolvable = true, n = n } end
  local good = SV.goodSet(G)
  local VL = V.compute(lvl, G, def, good)
  local live, vis, hid, washed, nwin = 0, 0, 0, 0, 0
  local hidden = {}
  local winCfg = {}
  local function cfgKey(st)
    local t = {}
    for q, p in ipairs(lvl.pieces) do if p.movable then t[#t + 1] = st.pos[q] .. (st.fixed[q] and "f" or "") end end
    return table.concat(t, ",")
  end
  for i = 1, G.n do
    if G.flag[i] == 1 then nwin = nwin + 1; winCfg[cfgKey(R.decode(lvl, G.keys[i]))] = true end
    if G.flag[i] == 2 then washed = washed + 1 else
      if good[i] == 1 then live = live + 1 elseif VL.newbie[i] then vis = vis + 1 else hid = hid + 1; hidden[i] = true end
    end
  end
  local nWinCfg = 0; for _ in pairs(winCfg) do nWinCfg = nWinCfg + 1 end
  local winFixed = true
  do local ws = R.decode(lvl, G.keys[G.firstWin]); for q, p in ipairs(lvl.pieces) do if p.movable and not ws.fixed[q] then winFixed = false end end end
  local EX = V.measure(G, good, VL.newbie)
  local EXP = V.measure(G, good, VL.expert)
  local path = EX.path
  local opt = EX.opt
  -- события с деталями, прогулка, вынужденные, безопасные ходы
  local function objs(i) local st = R.decode(lvl, G.keys[i]); local t = {}; for q = 1, #st.pos do t[#t + 1] = st.pos[q] .. (st.fixed[q] and "f" or "") end; return table.concat(t, ",") end
  -- события с якорями (для сведения, как в build/l2c): прикрутился/открутился конец
  local function anch(i) local st = R.decode(lvl, G.keys[i]); local pc = R.occupancy(st); return tostring(R.endScrew(lvl, st, pc, "head")) .. "/" .. tostring(R.endScrew(lvl, st, pc, "heel")) end
  local streak2, maxStreak2 = 0, 0
  for i = 1, #path - 1 do
    if objs(path[i]) ~= objs(path[i + 1]) or anch(path[i]) ~= anch(path[i + 1]) then streak2 = 0 else streak2 = streak2 + 1; if streak2 > maxStreak2 then maxStreak2 = streak2 end end
  end
  local safeSeq, streak, maxStreak, events, forced, maxForced = {}, 0, 0, 0, 0, 0
  for i = 1, #path - 1 do
    local s, safe = path[i], 0
    for e = G.eStart.p[s - 1], G.eStart.p[s] - 1 do if good[G.edges.p[e]] == 1 then safe = safe + 1 end end
    safeSeq[#safeSeq + 1] = safe
    if safe <= 1 then forced = forced + 1; if forced > maxForced then maxForced = forced end else forced = 0 end
    if objs(path[i]) ~= objs(path[i + 1]) then events = events + 1; streak = 0 else streak = streak + 1; if streak > maxStreak then maxStreak = streak end end
  end
  local sx = (not opts.fast) and ST.check(def, opts.cap or 3000000) or nil
  local r = {
    winFixed = winFixed, opt = opt, n = G.n, live = live, vis = vis, hid = hid, washed = washed, nwin = nwin, nWinCfg = nWinCfg,
    hiddenPct = 100 * hid / math.max(1, hid + live), smart = EX.smart, deep = EX.maxDeep, deepList = EX.deepList,
    expertPct = EXP.hiddenPct, expertSmart = EXP.smart, expertDeep = EXP.maxDeep,
    monkey = sx and sx.monkey, shortest = sx and sx.shortest, width = sx and sx.maxWidth,
    events = events, walk = maxStreak, walk2 = maxStreak2, forced = maxForced, safe = table.concat(safeSeq, ""),
  }
  local fails = {}
  if opt < 15 or opt > 40 then fails[#fails + 1] = "ходов" end
  if events < 2 then fails[#fails + 1] = "событий" end
  if r.hiddenPct < 40 then fails[#fails + 1] = "скрытых" end
  if r.smart > 0.2 then fails[#fails + 1] = "обезьяна" end
  if r.monkey and r.monkey > 1 then fails[#fails + 1] = "наобум" end
  if r.deep < 8 then fails[#fails + 1] = "глубина" end
  if maxStreak > 6 then fails[#fails + 1] = "прогулка" end
  if maxForced > 3 then fails[#fails + 1] = "вынужд" end
  if r.width and r.width > 3 then fails[#fails + 1] = "ширина" end
  if nWinCfg > 1 then fails[#fails + 1] = "конфигураций" end
  r.fails = fails
  r.line = string.format("ходов %d | сост. %d (жив %d, вид %d, скр %d, смыт %d) | скрытых %.0f%% | обезьяна %.2f%% | глубина %d | наобум %.3f%% | кратч %d шир %d | событий %d прогулка %d (с якорями %d) вынужд %d | конф %d | знаток %.0f%%",
    opt, G.n, live, vis, hid, washed, r.hiddenPct, r.smart, r.deep, r.monkey or -1, r.shortest or -1, r.width or -1, events, maxStreak, maxStreak2, maxForced, nWinCfg, r.expertPct)
  if opts.ablations and def.ablations then
    local abl = SV.ablations(def, { cap = opts.cap or 3000000 })
    local ab = {}
    for _, a in ipairs(abl) do ab[#ab + 1] = a.name .. "=" .. (a.solvable == false and "нерешаем" or "РЕШАЕМ") end
    r.abl = table.concat(ab, ", ")
  end
  SV.freeGraph(G); require("ffi").C.free(good)
  return r
end

return M
