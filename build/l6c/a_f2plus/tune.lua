-- build/l6c/a_f2plus/tune.lua файл.lua [pairs] — локальная доводка ядра: одиночные (и парные) правки стен
-- внутри поля при неподвижных объектах. Печатает только метрики и координаты правок (без ходов).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local base = dofile(arg[1])
local doPairs = arg[2] == "pairs"
local function metrics(def)
  local ok, lvl = pcall(R.compile, def)
  if not ok then return nil end
  if #R.validate(lvl) > 0 then return nil end
  local G = SV.explore(lvl, 400000)
  if not G or not G.firstWin then if G then SV.freeGraph(G) end return nil end
  local good = SV.goodSet(G)
  local st = {}
  local function S(i) st[i] = st[i] or R.decode(lvl, G.keys[i]); return st[i] end
  local function lost(s)
    for q, p in ipairs(lvl.pieces) do if p.movable and s.pos[q] == 0 then return true end end
    return def.visibleLoss and def.visibleLoss(lvl, s) or false
  end
  local live, hid, nwin = 0, 0, 0
  for i = 1, G.n do
    if G.flag[i] == 1 then nwin = nwin + 1 end
    if G.flag[i] ~= 2 then if good[i] == 1 then live = live + 1 elseif not lost(S(i)) then hid = hid + 1 end end
  end
  local opt = G.depth[G.firstWin]
  local T = 5 * opt
  local p, okp = { [1] = 1.0 }, 0
  for _ = 1, T do
    local np = {}
    for i, pr in pairs(p) do
      local cand = {}
      for e = G.eStart.p[i - 1], G.eStart.p[i] - 1 do
        local j = G.edges.p[e]
        if G.flag[j] == 1 then cand[#cand + 1] = j elseif G.flag[j] ~= 2 and not lost(S(j)) then cand[#cand + 1] = j end
      end
      if #cand == 0 then np[i] = (np[i] or 0) + pr else
        local share = pr / #cand
        for _, j in ipairs(cand) do if G.flag[j] == 1 then okp = okp + share else np[j] = (np[j] or 0) + share end end
      end
    end
    p = np
  end
  local smart = 100 * (1 - (1 - okp) ^ (1000 / T))
  local res = { opt = opt, n = G.n, hid = 100 * hid / math.max(1, hid + live), smart = smart, wins = nwin }
  SV.freeGraph(G); require("ffi").C.free(good)
  return res
end
local H, W = #base.grid, #base.grid[1]
local cells = {}
for y = 2, H - 1 do for x = 2, W - 1 do
  local occ = false
  for _, o in ipairs(base.objects) do
    if o.at and o.at[1] == x and o.at[2] == y then occ = true end
    if o.cells then for _, c in ipairs(o.cells) do if c[1] == x and c[2] == y then occ = true end end end
  end
  if not occ then cells[#cells + 1] = { x, y } end
end end
local function apply(d, list)
  for _, c in ipairs(list) do
    local row = d.grid[c[2]]; local ch = row:sub(c[1], c[1])
    d.grid[c[2]] = row:sub(1, c[1] - 1) .. (ch == "#" and "." or "#") .. row:sub(c[1] + 1)
  end
end
local b = metrics(base)
print(string.format("база: ходов %d сост %d скрытых %.0f%% обезьяна %.2f%% выигр %d", b.opt, b.n, b.hid, b.smart, b.wins))
local function try(list)
  local d = SV.deepcopy(base); apply(d, list)
  local m = metrics(d)
  if m and m.wins == 1 and m.opt >= 12 and (m.smart < b.smart * 0.8 or m.hid > b.hid + 3) then
    local t = {}
    for _, c in ipairs(list) do local ch = base.grid[c[2]]:sub(c[1], c[1]); t[#t + 1] = (ch == "#" and "-" or "+") .. c[1] .. "," .. c[2] end
    print(string.format("%-16s ходов %d сост %d скрытых %.0f%% обезьяна %.2f%%", table.concat(t, " "), m.opt, m.n, m.hid, m.smart))
  end
end
for i = 1, #cells do try({ cells[i] }) end
if doPairs then for i = 1, #cells do for j = i + 1, #cells do try({ cells[i], cells[j] }) end end end
