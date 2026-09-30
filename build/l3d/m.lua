-- build/l3d/m.lua — быстрые метрики кандидата (без ходов): ходы, скрытые (линейка vislib), прогулки, двери по половинам.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local M = {}
function M.run(def, pocket)
  local lvl = R.compile(def)
  local errs = R.validate(lvl)
  if #errs > 0 then return { err = table.concat(errs, ";") } end
  local G = SV.explore(lvl, 3000000)
  if not G then return { err = "CAP" } end
  if not G.firstWin then local n = G.n; SV.freeGraph(G); return { unsolv = true, n = n } end
  local good = SV.goodSet(G)
  V.POCKET = pocket or tonumber(os.getenv("POCKET") or 4)
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
-- M.wallDead(def): сетка, где замурованы пустые клетки без роли — ни в одном живом состоянии и ни в одном
-- состоянии сразу за дверью (приманка) в них нет ни Лапидуса, ни мыла. Возвращает новую сетку и число клеток.
function M.wallDead(def, pocket)
  local lvl = R.compile(def)
  local G = SV.explore(lvl, 3000000)
  if not G or not G.firstWin then SV.freeGraph(G) return nil end
  local good = SV.goodSet(G)
  V.POCKET = pocket or 4
  local VL = V.compute(lvl, G, def, good)
  local ES, E, flag = G.eStart.p, G.edges.p, G.flag
  local used = {}
  local function mark(i)
    local st = R.decode(lvl, G.keys[i])
    for _, c in ipairs(st.body) do used[c] = true end
    for q = 1, #st.pos do if st.pos[q] ~= 0 then used[st.pos[q]] = true end end
  end
  for i = 1, G.n do
    if flag[i] ~= 2 and good[i] == 1 then
      mark(i)
      for e = ES[i-1], ES[i]-1 do local j = E[e]; if flag[j] == 0 and good[j] ~= 1 and not VL.newbie[j] then mark(j) end end
    end
  end
  local g, n = {}, 0
  for y = 1, lvl.H do
    local row = def.grid[y]
    local out = {}
    for x = 1, lvl.W do
      local ch = row:sub(x, x)
      if ch == "." and not used[(y-1)*lvl.W + x] then ch = "#"; n = n + 1 end
      out[x] = ch
    end
    g[y] = table.concat(out)
  end
  SV.freeGraph(G); require("ffi").C.free(good)
  return g, n
end
if arg and arg[0] and arg[0]:match("m%.lua$") and arg[1] then
  local d = dofile(arg[1])
  print("карман4: " .. M.fmt(M.run(d, 4)))
  print("карман5: " .. M.fmt(M.run(d, 5)))
  local g, n = M.wallDead(d)
  if g then
    local d2 = dofile(arg[1]); d2.grid = g
    print(string.format("замуровано %d клеток без роли: %s | карман5 %.1f%%", n, M.fmt(M.run(d2, 4)), (M.run(d2, 5).hid or 0)))
  end
end
return M
