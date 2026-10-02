-- ev.lua файл.lua [pic|-] [N] [режим переписи] — всё разом по ОДНОМУ графу: проверка раскладки, решаемость,
-- метрики: «новичок» — gnov.lua (смыта, никогда не сдвинется, никогда не поднимется, выход занят тупиковой резьбой —
-- точно, по графу; ворота считаю по ней как по самой широкой новичковой); «линейка» — tools/vislib.lua без правил уровня
-- (как check.lua для файла без visibleLoss); «знаток» — tools/vislib.lua (для сведения, как в check.lua);
-- «знаток-точно» — gvis3 (F J I L + N наибольшей неподвижной точкой). Перепись скрытых классов — по «новичку».
-- Ходов и кадров не печатает (pic — только стартовый кадр).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local GV = dofile("build/l7c/d_tee_lift/gvis3.lua")
local VL = require("tools.vislib")
local GN = dofile("build/l7c/d_tee_lift/gnov.lua")
local def = dofile(arg[1])
local name = arg[1]:match("([^/]+)$")
local lvl = R.compile(def)
local errs, warns = R.validate(lvl)
if #errs > 0 then print(name .. ": ОШИБКИ " .. table.concat(errs, "; ")) return end
for _, w in ipairs(warns) do print(name .. ": warning " .. w) end
local SYM = { source = "S", fixture = "F", stub = "T", pipe = "=", fitting = "b", porcelain = "P" }
local function draw(s)
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x]; rows[y][x] = c == 1 and "#" or (c == 2 and "~" or ".") end end
  for _, j in ipairs(R.jets(lvl, s)) do for _, c in ipairs(j.cells) do local x, y = R.xy(lvl, c); rows[y][x] = (j.dir == 1 or j.dir == 3) and "|" or "-" end end
  for q, pp in ipairs(lvl.pieces) do if s.pos[q] ~= 0 then local x, y = R.xy(lvl, s.pos[q]); local ch
    if pp.movable then ch = (pp.tag and pp.tag:sub(1,1)) or "b"; ch = s.fixed[q] and ch:upper() or ch:lower() else ch = SYM[pp.kind] end; rows[y][x] = ch end end
  for k, c in ipairs(s.body) do local x, y = R.xy(lvl, c); rows[y][x] = (k == #s.body) and "H" or ((k == 1) and "f" or "o") end
  for y = 1, lvl.H do print("   " .. table.concat(rows[y])) end
end
if arg[2] == "pic" then draw(R.newState(lvl)) end
local G = SV.explore(lvl, 3000000)
if not G then print(name .. ": CAP") return end
if not G.firstWin then print(string.format("%s: НЕРЕШАЕМ (состояний %d)", name, G.n)) SV.freeGraph(G) return end
local good = SV.goodSet(G)
local n = G.n
local nwin = 0
for i = 1, n do if G.flag[i] == 1 then nwin = nwin + 1 end end
local marks = GV.compute(lvl, G, def)
local vl = VL.compute(lvl, G, def, good)
local nov = GN.compute(lvl, G, def)
local function vis(i, mode)
  if mode == "новичок" then return nov[i] and true or false end
  if mode == "линейка" then return vl.newbie[i] and true or false end
  if mode == "знаток" then return vl.expert[i] and true or false end
  local m = marks[i]
  return (m and m ~= "D" and m ~= "d") and true or false
end
local opt = G.depth[G.firstWin]
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
local function metrics(mode)
  local live, hid, nv, liveMarked = 0, 0, 0, 0
  local hidden = {}
  for i = 1, n do
    if G.flag[i] ~= 2 then
      if good[i] == 1 then live = live + 1; if vis(i, mode) then liveMarked = liveMarked + 1 end
      elseif vis(i, mode) then nv = nv + 1
      else hid = hid + 1; hidden[i] = true end
    end
  end
  local T = 5 * opt
  local p, ok = { [1] = 1.0 }, 0
  for _ = 1, T do
    local np = {}
    for i, pr in pairs(p) do
      local cand = {}
      for e = G.eStart.p[i - 1], G.eStart.p[i] - 1 do
        local j = G.edges.p[e]
        if G.flag[j] == 1 then cand[#cand + 1] = j elseif G.flag[j] ~= 2 and not vis(j, mode) then cand[#cand + 1] = j end
      end
      if #cand == 0 then np[i] = (np[i] or 0) + pr else
        local share = pr / #cand
        for _, j in ipairs(cand) do if G.flag[j] == 1 then ok = ok + share else np[j] = (np[j] or 0) + share end end
      end
    end
    p = np
  end
  local smart = 100 * (1 - (1 - ok) ^ (1000 / T))
  local function depthFrom(j)
    local d, q, h, maxd = { [j] = 0 }, { j }, 1, 0
    while h <= #q do
      local u = q[h]; h = h + 1
      for e = G.eStart.p[u - 1], G.eStart.p[u] - 1 do
        local v = G.edges.p[e]
        if hidden[v] and d[v] == nil then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; q[#q + 1] = v end
      end
    end
    return maxd
  end
  local maxDeep, dl = 0, {}
  for k = 1, #path - 1 do
    local s, best = path[k], -1
    for e = G.eStart.p[s - 1], G.eStart.p[s] - 1 do
      local j = G.edges.p[e]
      if hidden[j] then local d = depthFrom(j); if d > best then best = d end end
    end
    if best >= 0 then dl[#dl + 1] = (k - 1) .. ":" .. best; if best > maxDeep then maxDeep = best end end
  end
  return string.format("[%s] живых %d, видимых %d, скрытых %d → СКРЫТЫХ %.1f %% | обезьяна %.3f %% | глубина %d {%s}%s",
    mode, live, nv, hid, 100 * hid / math.max(1, hid + live), smart, maxDeep, table.concat(dl, " "),
    liveMarked > 0 and (" | !!! помечено живых " .. liveMarked) or ""), hidden
end
local function objs(i) local st = R.decode(lvl, G.keys[i]); local t = {}; for q = 1, #st.pos do t[#t+1] = st.pos[q] .. (st.fixed[q] and "f" or "") end; return table.concat(t, ",") end
local streak, maxStreak, events, forced, maxForced = 0, 0, 0, 0, 0
local safeSeq = {}
for i = 1, #path - 1 do
  local s, safe = path[i], 0
  for e = G.eStart.p[s-1], G.eStart.p[s]-1 do if good[G.edges.p[e]] == 1 then safe = safe + 1 end end
  safeSeq[#safeSeq + 1] = safe
  if safe <= 1 then forced = forced + 1; if forced > maxForced then maxForced = forced end else forced = 0 end
  if objs(path[i]) ~= objs(path[i+1]) then events = events + 1; streak = 0 else streak = streak + 1; if streak > maxStreak then maxStreak = streak end end
end
local E, ES = G.edges.p, G.eStart.p
local rev = {}
for i = 1, n do for e = ES[i - 1], ES[i] - 1 do local j = E[e]; local t = rev[j]; if not t then t = {}; rev[j] = t end; t[#t + 1] = i end end
local dw, q, h = {}, {}, 1
for i = 1, n do if G.flag[i] == 1 then dw[i] = 0; q[#q + 1] = i end end
while h <= #q do local u = q[h]; h = h + 1; for _, pp in ipairs(rev[u] or {}) do if dw[pp] == nil and G.flag[pp] ~= 2 then dw[pp] = dw[u] + 1; q[#q + 1] = pp end end end
local w = {}
for i = 1, n do if dw[i] and G.depth[i] + dw[i] == opt then w[G.depth[i]] = (w[G.depth[i]] or 0) + 1 end end
local maxw = 0
for d = 0, opt do if (w[d] or 0) > maxw then maxw = w[d] end end
print(string.format("%s: ходов %d | сост. %d | выигрышных %d | прогулка %d | вынужд. %d | ширина %d | событий %d | безоп. %s",
  name, opt, n, nwin, maxStreak, maxForced, maxw, events, table.concat(safeSeq, "")))
local cens = arg[4] or "новичок"
local hidC
for _, mode in ipairs({ "новичок", "линейка", "знаток", "знаток-точно" }) do
  local line, hs = metrics(mode)
  print("   " .. line)
  if mode == cens then hidC = hs end
end
local function tally(arr)
  local l = {}
  for i = 1, n do if G.flag[i] ~= 2 and good[i] ~= 1 then local m = arr[i] or "-"; l[m] = (l[m] or 0) + 1 end end
  local s = {}
  for k, v in pairs(l) do s[#s + 1] = k .. "=" .. v end
  table.sort(s)
  return table.concat(s, " ")
end
print("   тупики: новичок " .. tally(nov) .. " | знаток-точно " .. tally(marks))
local agg = {}
for i = 1, n do
  if hidC[i] then
    local st = R.decode(lvl, G.keys[i])
    local t = {}
    for qq, p in ipairs(lvl.pieces) do if p.movable then
      if st.pos[qq] == 0 then t[#t+1] = (p.tag or p.what) .. "=смыт" else
        local xx, yy = R.xy(lvl, st.pos[qq]); t[#t+1] = string.format("%s(%d,%d)%s%s", p.tag or p.what, xx, yy, st.fixed[qq] and "F" or "", st.asm[qq] ~= qq and ("~" .. st.asm[qq]) or "") end end end
    local up = false
    for _, j in ipairs(R.jets(lvl, st)) do if j.dir == 1 and not j.lapidus and #j.cells > 0 then up = true end end
    t[#t+1] = up and "фонтан" or "-"
    local k = table.concat(t, " ")
    agg[k] = (agg[k] or 0) + 1
  end
end
local list = {}
for k, v in pairs(agg) do list[#list + 1] = { k, v } end
table.sort(list, function(a, b) return a[2] > b[2] end)
for i = 1, math.min(tonumber(arg[3] or 8), #list) do print(string.format("   скрыто[%s] %6d  %s", cens, list[i][2], list[i][1])) end
SV.freeGraph(G); require("ffi").C.free(good)
