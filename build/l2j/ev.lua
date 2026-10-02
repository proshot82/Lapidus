-- build/l2j/ev.lua — компактная оценка кандидата (те же ворота, что check.lua), для перебора вариаций ручного скелета.
-- local EV = dofile("build/l2j/ev.lua"); print(EV.line(def))
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local ST = require("solver.strict")
local V = require("tools.vislib")
local M = {}
function M.eval(def, cap)
  cap = cap or 2000000
  local lvl = R.compile(def)
  local errs = R.validate(lvl)
  if #errs > 0 then return { err = table.concat(errs, "; ") } end
  local G = SV.explore(lvl, cap)
  if not G then return { err = "CAP" } end
  local good = SV.goodSet(G)
  if not G.firstWin then SV.freeGraph(G); require("ffi").C.free(good); return { unsolvable = true, n = G.n } end
  local VL = V.compute(lvl, G, def, good)
  local live, vis, hid, washed = 0, 0, 0, 0
  local hidden = {}
  for i = 1, G.n do
    if G.flag[i] == 2 then washed = washed + 1
    elseif good[i] == 1 then live = live + 1 elseif VL.newbie[i] then vis = vis + 1 else hid = hid + 1; hidden[i] = true end
  end
  local EX = V.measure(G, good, VL.newbie)
  local path = EX.path
  local halves, doorsAll = { 0, 0 }, 0
  for i = 1, G.n do if good[i] == 1 then
    for e = G.eStart.p[i - 1], G.eStart.p[i] - 1 do if hidden[G.edges.p[e]] then doorsAll = doorsAll + 1 end end
  end end
  local doorsAt = {}
  for k = 1, #path - 1 do
    local s, c = path[k], 0
    for e = G.eStart.p[s - 1], G.eStart.p[s] - 1 do if hidden[G.edges.p[e]] then c = c + 1 end end
    if c > 0 then doorsAt[#doorsAt + 1] = (k - 1) .. ":" .. c; local h = (k - 1) < (#path - 1) / 2 and 1 or 2; halves[h] = halves[h] + 1 end
  end
  local sx = ST.check(def, cap)
  local abl = SV.ablations(def, { cap = cap })
  local ab = {}
  for _, a in ipairs(abl) do ab[#ab + 1] = a.name .. "=" .. (a.solvable == false and "нереш" or "РЕШ") end
  local res = { moves = EX.opt, n = G.n, live = live, vis = vis, hid = hid, washed = washed,
    hidPct = EX.hiddenPct, smart = EX.smart, deep = EX.maxDeep, deepList = EX.deepList,
    doors = table.concat(doorsAt, " "), h1 = halves[1], h2 = halves[2], doorsAll = doorsAll,
    monkey = sx and sx.monkey, shortest = sx and sx.shortest, width = sx and sx.maxWidth, abl = table.concat(ab, ", ") }
  SV.freeGraph(G); require("ffi").C.free(good)
  return res
end
function M.line(def, cap)
  local r = M.eval(def, cap)
  if r.err then return "ОШИБКА " .. r.err end
  if r.unsolvable then return string.format("НЕРЕШАЕМ (%d)", r.n) end
  return string.format("ход %2d | сост %5d жив %4d вид %4d скр %4d смыт %4d | СКР %3.0f%% обез %5.2f%% глуб %2d | двери %d/%d [%s] | шир %s кратч %s наобум %.2f | %s",
    r.moves, r.n, r.live, r.vis, r.hid, r.washed, r.hidPct, r.smart, r.deep, r.h1, r.h2, r.doors, tostring(r.width), tostring(r.shortest), r.monkey or -1, r.abl)
end
if arg and arg[0] and arg[0]:match("ev%.lua$") and arg[1] then
  for i = 1, #arg do print(arg[i] .. ": " .. M.line(dofile(arg[i]))) end
end
return M
