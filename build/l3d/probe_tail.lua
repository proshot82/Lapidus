-- build/l3d/probe_tail.lua [N] [seed] — разведка: бывает ли финал короче при левой части кв. 3 без изменений.
-- Случайно меняет правую часть (x 7..10, y 2..7) и места стояка/мойки; печатает только сетки и метрики (без ходов).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local base = dofile("levels/03.lua")
local N, seed = tonumber(arg[1] or 300), tonumber(arg[2] or 1)
math.randomseed(seed)
local function lastWalk(def)
  local lvl = R.compile(def)
  if #R.validate(lvl) > 0 then return nil end
  local G = SV.explore(lvl, 200000)
  if not G or not G.firstWin then SV.freeGraph(G) return nil end
  local path, x = {}, G.firstWin
  while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
  table.insert(path, 1, 1)
  local function objs(i) local st = R.decode(lvl, G.keys[i]); local t = {}; for q = 1, #st.pos do t[#t+1] = st.pos[q] end; return table.concat(t, ",") end
  local w, streak, mx = {}, 0, 0
  for k = 1, #path - 1 do if objs(path[k]) ~= objs(path[k+1]) then w[#w+1] = streak; streak = 0 else streak = streak + 1 end end
  w[#w+1] = streak
  for _, v in ipairs(w) do if v > mx then mx = v end end
  local opt, n = G.depth[G.firstWin], G.n
  SV.freeGraph(G)
  return opt, streak, mx, n, table.concat(w, ",")
end
local function nosoap(def)
  local d = SV.deepcopy(def); d.ablations = nil
  local k = {}; for _, o in ipairs(d.objects) do if o.kind ~= "porcelain" then k[#k+1] = o end end; d.objects = k
  local lvl = R.compile(d); if #R.validate(lvl) > 0 then return false end
  local G = SV.explore(lvl, 200000); local s = G and G.firstWin ~= nil; SV.freeGraph(G); return s
end
local DIRS = { up = {0,-1}, right = {1,0}, down = {0,1}, left = {-1,0} }
local seen, best = {}, {}
for it = 1, N do
  local d = SV.deepcopy(base)
  local g = {}
  for y = 1, #d.grid do g[y] = {}; for x = 1, #d.grid[y] do g[y][x] = d.grid[y]:sub(x,x) end end
  for y = 2, 7 do for x = 7, 10 do g[y][x] = (math.random() < 0.45) and "." or "#" end end
  g[7][7] = "."; g[6][7] = "."
  local open = {}
  for y = 2, 7 do for x = 5, 10 do if g[y][x] == "." then open[#open+1] = {x, y} end end end
  if #open < 6 then goto cont end
  do
    local s, f = open[math.random(#open)], open[math.random(#open)]
    if s == f then goto cont end
    local function port(c)
      local ks = {}
      for k, v in pairs(DIRS) do local nx, ny = c[1]+v[1], c[2]+v[2]; if g[ny] and g[ny][nx] == "." and not (nx == s[1] and ny == s[2]) and not (nx == f[1] and ny == f[2]) then ks[#ks+1] = k end end
      if #ks == 0 then return nil end
      return ks[math.random(#ks)]
    end
    local ps, pf = port(s), port(f)
    if not ps or not pf then goto cont end
    for y = 1, #g do d.grid[y] = table.concat(g[y]) end
    d.objects[1] = { at = s, kind = "source", ports = { [ps] = "V" } }
    d.objects[2] = { at = f, kind = "fixture", ports = { [pf] = "N" }, what = "sink" }
    local key = table.concat(d.grid, "|") .. s[1] .. s[2] .. ps .. f[1] .. f[2] .. pf
    if seen[key] then goto cont end
    seen[key] = true
    local opt, lw, mx, n, ws = lastWalk(d)
    if opt and lw <= 7 and opt >= 20 and not nosoap(d) then
      print(string.format("ходов %d хвост %d max %d n %d [%s] S(%d,%d)%s F(%d,%d)%s", opt, lw, mx, n, ws, s[1], s[2], ps, f[1], f[2], pf))
      for y = 1, #d.grid do print("  " .. d.grid[y]) end
      io.stdout:flush()
    end
  end
  ::cont::
end
