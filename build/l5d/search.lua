-- build/l5d/search.lua seed N [out] — мутатор-разведчик для кв. 5: случайные раскладки вокруг скелета
-- «стояк внизу, гнездо заглушки слева от места тройника», фильтр по воротам 30.09 (двери в обеих половинах,
-- ступенька обязательна, лишний выход обязателен). Печатает только метрики и раскладки (решений нет).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local V = require("tools.vislib")
local seed, N, out = tonumber(arg[1] or 1), tonumber(arg[2] or 100), arg[3]
math.randomseed(seed)
local W, H = tonumber(os.getenv("W") or 10), 8
local fo = out and io.open(out, "a") or io.stdout
local function noStep(lvl, st, ns)
  local pq
  for q, p in ipairs(lvl.pieces) do if p.what == "plug" then pq = q end end
  local c = ns.pos[pq]
  if c == 0 or ns.fixed[pq] then return true end
  local above = lvl.nb[c][1]
  local on = false
  for _, b in ipairs(ns.body) do if b == above then on = true end end
  if not on then return true end
  local pr = math.floor((c - 1) / lvl.W) + 1
  for _, b in ipairs(ns.body) do if math.floor((b - 1) / lvl.W) + 1 <= pr - 4 then return false end end
  return true
end
local function gen()
  local g = {}
  for y = 1, H do g[y] = {} for x = 1, W do g[y][x] = (x == 1 or x == W or y == 1 or y == H) and "#" or "." end end
  -- случайные блоки стен
  local nb = math.random(4, 9)
  for _ = 1, nb do
    local x, y = math.random(2, W - 1), math.random(2, H - 1)
    local w, h = math.random(1, 3), math.random(1, 3)
    for yy = y, math.min(H - 1, y + h - 1) do for xx = x, math.min(W - 1, x + w - 1) do g[yy][xx] = "#" end end
  end
  local rx = math.random(4, W - 2)
  -- стояк в нижнем ряду, T и P открыты
  g[7][rx] = "."; g[7][rx - 1] = "."; g[7][rx - 2] = "."
  local objs = {}
  objs[#objs + 1] = { kind = "source", at = { rx, 7 }, ports = { left = "N" } }
  local function freeCell()
    for _ = 1, 200 do
      local x, y = math.random(2, W - 1), math.random(2, H - 1)
      if g[y][x] == "." and not (x == rx and y == 7) then
        local taken = false
        for _, o in ipairs(objs) do if o.at and o.at[1] == x and o.at[2] == y then taken = true end
          if o.cells then for _, c in ipairs(o.cells) do if c[1] == x and c[2] == y then taken = true end end end end
        if not taken then return x, y end
      end
    end
  end
  -- сушитель: у стены, порт в открытую клетку
  local dx, dy = freeCell(); if not dx then return nil end
  local dirs = { { "left", -1, 0 }, { "right", 1, 0 }, { "up", 0, -1 }, { "down", 0, 1 } }
  local okd = {}
  for _, d in ipairs(dirs) do local x2, y2 = dx + d[2], dy + d[3]; if g[y2] and g[y2][x2] == "." then okd[#okd + 1] = d[1] end end
  if #okd == 0 then return nil end
  objs[#objs + 1] = { kind = "fixture", what = "dryer", at = { dx, dy }, ports = { [okd[math.random(#okd)]] = "N" } }
  local tx, ty = freeCell(); if not tx then return nil end
  objs[#objs + 1] = { kind = "fitting", what = "tee", tag = "tee", at = { tx, ty }, ports = { up = "V", right = "V", left = "V" } }
  local px, py = freeCell(); if not px then return nil end
  objs[#objs + 1] = { kind = "fitting", what = "plug", tag = "plug", at = { px, py }, ports = { right = "N" } }
  local lx, ly = freeCell(); if not lx then return nil end
  local cells = { { lx, ly } }
  for _ = 1, 2 do
    local c = cells[#cells]
    local cand = {}
    for _, d in ipairs(dirs) do
      local x2, y2 = c[1] + d[2], c[2] + d[3]
      if g[y2] and g[y2][x2] == "." then
        local bad = false
        for _, o in ipairs(objs) do if o.at and o.at[1] == x2 and o.at[2] == y2 then bad = true end end
        for _, cc in ipairs(cells) do if cc[1] == x2 and cc[2] == y2 then bad = true end end
        if not bad then cand[#cand + 1] = { x2, y2 } end
      end
    end
    if #cand == 0 then return nil end
    cells[#cells + 1] = cand[math.random(#cand)]
  end
  objs[#objs + 1] = { kind = "lapidus", cells = cells, head = 1 }
  local grid = {}
  for y = 1, H do grid[y] = table.concat(g[y]) end
  local L = ({ { 2, 4 }, { 2, 4 }, { 2, 5 }, { 3, 5 } })[math.random(4)]
  return { id = 5, flat = 5, name = "Лишний выход", length = L, pressure = 0, grid = grid, objects = objs }
end
local function solvable(def, filter)
  local ok, lvl = pcall(R.compile, def)
  if not ok or #R.validate(lvl) > 0 then return false end
  local okn, G = pcall(SV.explore, lvl, 200000, filter)
  if not okn or not G then return nil end
  local s = G.firstWin ~= nil
  SV.freeGraph(G)
  return s
end
local tried, hits = 0, 0
local st = { solv = 0, gate = 0, step = 0 }
for it = 1, N do
  local def = gen()
  if def then
    local ok, lvl = pcall(R.compile, def)
    if ok and #R.validate(lvl) == 0 then
      tried = tried + 1
      local okn, G = pcall(SV.explore, lvl, 200000)
      if okn and G and G.firstWin then st.step = st.step + 1; HIST = HIST or {}; local o = G.depth[G.firstWin]; HIST[o] = (HIST[o] or 0) + 1 end
      if not okn and not ERRP then ERRP = true; print("ERR", G) end
      if okn and G and G.firstWin and G.depth[G.firstWin] >= 15 and G.depth[G.firstWin] <= 34 then
        st.solv = st.solv + 1
        local good = SV.goodSet(G)
        local VL = V.compute(lvl, G, def, good)
        local m = V.measure(G, good, VL.newbie)
        local ES, E, flag, n = G.eStart.p, G.edges.p, G.flag, G.n
        -- двери с одного кратчайшего пути, по половинам, со «стойкостью» (мин ходов до видимого)
        local h1, h2, best1, best2 = 0, 0, 0, 0
        for k = 1, #m.path - 1 do
          local s = m.path[k]
          for e = ES[s-1], ES[s]-1 do local j = E[e]
            if m.hidden[j] then
              local d, qx, hx, rev = { [j] = 0 }, { j }, 1, nil
              while hx <= #qx and not rev do local u = qx[hx]; hx = hx + 1
                for ee = ES[u-1], ES[u]-1 do local v = E[ee]
                  if flag[v] == 0 and good[v] ~= 1 and VL.newbie[v] then rev = d[u] + 1 break end
                  if m.hidden[v] and d[v] == nil then d[v] = d[u] + 1; qx[#qx+1] = v end end end
              rev = rev or 99
              if (k - 1) < m.opt / 2 then h1 = h1 + 1; if rev > best1 then best1 = rev end else h2 = h2 + 1; if rev > best2 then best2 = rev end end
            end end end
        -- прогулка
        local function objs(i) local st = VL.states[i]; local t = {}; for q = 1, #st.pos do t[#t+1] = st.pos[q] .. (st.fixed[q] and "f" or "") end; return table.concat(t, ",") end
        local streak, walk = 0, 0
        for k = 1, #m.path - 1 do if objs(m.path[k]) ~= objs(m.path[k+1]) then streak = 0 else streak = streak + 1; if streak > walk then walk = streak end end end
        SV.freeGraph(G); require("ffi").C.free(good)
        if m.hiddenPct >= 20 and h1 > 0 and h2 > 0 and best1 >= 3 and best2 >= 3 and walk <= 7 and m.smart <= 0.5 then
          st.gate = st.gate + 1
          if os.getenv("LOOSE") then fo:write(string.format("GATE it %d: ходов %d скр %.0f%% обез %.3f прогулка %d двери %d/%d вскр %d/%d\n", it, m.opt, m.hiddenPct, m.smart, walk, h1, h2, best1, best2)) end
          local s1 = solvable(def, noStep)
          local d2 = SV.deepcopy(def); for i = #d2.objects, 1, -1 do local o = d2.objects[i]; if o.tag == "plug" then table.remove(d2.objects, i) elseif o.tag == "tee" then o.ports.left = nil end end
          local s2 = solvable(d2)
          if s1 == false and s2 == false then
            hits = hits + 1
            fo:write(string.format("HIT seed %d it %d | ходов %d n %d скр %.0f%% обез %.3f прогулка %d двери 1п %d(вскр %d) 2п %d(вскр %d) L %d-%d\n",
              seed, it, m.opt, n, m.hiddenPct, m.smart, walk, h1, best1, h2, best2, def.length[1], def.length[2]))
            for _, r in ipairs(def.grid) do fo:write("   " .. r .. "\n") end
            for _, o in ipairs(def.objects) do
              if o.at then fo:write(string.format("   %s %s (%d,%d) %s\n", o.kind, o.what or "", o.at[1], o.at[2], (function() local t = {} for k2, v in pairs(o.ports) do t[#t+1] = k2 .. "=" .. v end return table.concat(t, ",") end)()))
              else local t = {} for _, c in ipairs(o.cells) do t[#t+1] = "{" .. c[1] .. "," .. c[2] .. "}" end fo:write("   lapidus " .. table.concat(t, " ") .. " head=1\n") end
            end
            fo:flush()
          end
        end
      elseif okn and G then SV.freeGraph(G) end
    end
  end
end
local hs = {} for k, v in pairs(HIST or {}) do hs[#hs+1] = k .. ":" .. v end fo:write("solvable " .. st.step .. " opt " .. table.concat(hs, " ") .. "\n")
fo:write(string.format("done seed %d: tried %d solv %d gate %d hits %d\n", seed, tried, st.solv, st.gate, hits)); fo:flush()
