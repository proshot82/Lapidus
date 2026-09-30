-- build/l3d/m.lua — быстрые метрики кандидата (без ходов): ходы, скрытые (линейка vislib), прогулки, двери по половинам.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local M = {}
function M.run(def)
  local lvl = R.compile(def)
  local errs = R.validate(lvl)
  if #errs > 0 then return { err = table.concat(errs, ";") } end
  local G = SV.explore(lvl, 3000000)
  if not G then return { err = "CAP" } end
  if not G.firstWin then local n = G.n; SV.freeGraph(G); return { unsolv = true, n = n } end
  local good = SV.goodSet(G)
  local VL = V.compute(lvl, G, def, good)
  local m = V.measure(G, good, VL.newbie)
  local ES, E, flag = G.eStart.p, G.edges.p, G.flag
  local path = m.path
  local function objs(i) local st = R.decode(lvl, G.keys[i]); local t = {}; for q = 1, #st.pos do t[#t+1] = st.pos[q] end; return table.concat(t, ",") end
  local walks, streak = {}, 0
  for k = 1, #path - 1 do
    if objs(path[k]) ~= objs(path[k+1]) then walks[#walks+1] = streak; streak = 0 else streak = streak + 1 end
  end
  walks[#walks+1] = streak
  local doors, h = {}, { 0, 0 }
  local half = (#path - 1) / 2
  for k = 1, #path - 1 do
    local s, c = path[k], 0
    for e = ES[s-1], ES[s]-1 do if m.hidden[E[e]] then c = c + 1 end end
    if c > 0 then doors[#doors+1] = (k-1) .. ":" .. c; local hh = (k-1) < half and 1 or 2; h[hh] = h[hh] + 1 end
  end
  local nwin = 0
  for i = 1, G.n do if flag[i] == 1 then nwin = nwin + 1 end end
  local r = { opt = m.opt, n = G.n, hid = m.hiddenPct, smart = m.smart, deep = m.maxDeep, dl = m.deepList,
    walks = table.concat(walks, ","), maxwalk = math.max(unpack(walks)), doors = table.concat(doors, " "), h1 = h[1], h2 = h[2], nwin = nwin }
  SV.freeGraph(G); require("ffi").C.free(good)
  return r
end
function M.fmt(r)
  if r.err then return "ERR " .. r.err end
  if r.unsolv then return "НЕРЕШАЕМ n=" .. r.n end
  return string.format("ходов %d n=%d win=%d | скрытых %.1f%% обез %.3f глуб %d [%s] | прогулки %s | двери %s (%d/%d)",
    r.opt, r.n, r.nwin, r.hid, r.smart, r.deep, r.dl, r.walks, r.doors, r.h1, r.h2)
end
if arg and arg[0] and arg[0]:match("m%.lua$") and arg[1] then print(M.fmt(M.run(dofile(arg[1])))) end
return M
