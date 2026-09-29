-- sig.lua файл.lua [N] — перепись тупиков по «подписям» конфигурации (где каждая деталь: слева/справа от столба,
-- в столбе свободна (строка), закреплена у прибора / в основании / в стопке; с кем свинчена; сторона Лапидуса).
-- Для каждой подписи: сколько скрытых и видимых (по def.visibleLoss файла), сколько из них в одном ходе от кратчайшего
-- пути и глубина скрытой ветки из таких входов. Только вывод инструмента; решений и порядка ходов не печатает.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local TOP = tonumber(arg[2] or 25)
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
if not G or not G.firstWin then print("нерешаем"); os.exit(0) end
local good = SV.goodSet(G)
local E, ES = G.edges.p, G.eStart.p
local P = lvl.pieces
local src, fix
for q, p in ipairs(P) do if p.source then src = q elseif p.fixture then fix = q end end
local sx, sy = R.xy(lvl, P[src].start)
local function lost(st)
  for q, p in ipairs(P) do if p.movable and st.pos[q] == 0 then return true end end
  return def.visibleLoss and def.visibleLoss(lvl, st) or false
end
local function where(st, q)
  local c = st.pos[q]
  if c == 0 then return "смыт" end
  local x, y = R.xy(lvl, c)
  local s
  if x == sx then
    if st.fixed[q] then
      local nearFix = false
      for d = 1, 4 do if lvl.nb[c][d] == P[fix].start then nearFix = true end end
      s = (nearFix and "Fмойка" or (y >= sy - 3 and "Fниз" or "Fстолб")) .. y
    else s = "столб" .. y end
  else
    s = ((x < sx) and "Л" or "П") .. (st.fixed[q] and "F" or "") .. y
  end
  -- с кем свинчена (одна сборка или закреплены и смотрят резьбами)
  local mates = {}
  for r, p2 in ipairs(P) do
    if r ~= q and p2.movable and st.pos[r] ~= 0 then
      local same = (not st.fixed[q] and not st.fixed[r] and st.asm[q] == st.asm[r])
      if not same and st.fixed[q] and st.fixed[r] then
        local d = R.dirBetween(lvl, c, st.pos[r])
        if d and P[q].ports[d] and P[r].ports[R.OPP[d]] and R.match(P[q].ports[d], P[r].ports[R.OPP[d]]) then same = true end
      end
      if same then mates[#mates + 1] = p2.tag end
    end
  end
  if #mates > 0 then table.sort(mates); s = s .. "+" .. table.concat(mates, "") end
  return s
end
local function sig(st)
  local t = {}
  for q, p in ipairs(P) do if p.movable then t[#t + 1] = p.tag .. ":" .. where(st, q) end end
  local l, r, c = false, false, false
  for _, b in ipairs(st.body) do local x = R.xy(lvl, b); if x < sx then l = true elseif x > sx then r = true else c = true end end
  t[#t + 1] = "Лап:" .. (l and "Л" or "") .. (c and "С" or "") .. (r and "П" or "")
  return table.concat(t, " ")
end
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
local onPath = {}
for _, s in ipairs(path) do onPath[s] = true end
local adj = {}
for _, s in ipairs(path) do for e = ES[s - 1], ES[s] - 1 do local j = E[e]; if not onPath[j] then adj[j] = true end end end
local hidden, visF, S = {}, {}, {}
for i = 1, G.n do
  if G.flag[i] == 0 and good[i] ~= 1 then
    local st = R.decode(lvl, G.keys[i]); S[i] = st
    if lost(st) then visF[i] = true else hidden[i] = true end
  end
end
local function depthFrom(j)
  local d, q, h, maxd = { [j] = 0 }, { j }, 1, 0
  while h <= #q do
    local u = q[h]; h = h + 1
    for e = ES[u - 1], ES[u] - 1 do
      local v = E[e]
      if hidden[v] and d[v] == nil then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; q[#q + 1] = v end
    end
  end
  return maxd
end
local cls = {}
for i, st in pairs(S) do
  local k = sig(st)
  local c = cls[k]; if not c then c = { k = k, hid = 0, vis = 0, adjH = 0, adjV = 0, deep = -1 }; cls[k] = c end
  if hidden[i] then c.hid = c.hid + 1 else c.vis = c.vis + 1 end
  if adj[i] then
    if hidden[i] then c.adjH = c.adjH + 1; local d = depthFrom(i); if d > c.deep then c.deep = d end else c.adjV = c.adjV + 1 end
  end
end
local l = {}
for _, c in pairs(cls) do l[#l + 1] = c end
table.sort(l, function(a, b) return a.hid > b.hid end)
local th, tv = 0, 0
for _, c in ipairs(l) do th = th + c.hid; tv = tv + c.vis end
print(string.format("тупиков: скрытых %d, видимых %d; подписей %d. Скрытые по подписям (скр/вид | у пути скр/вид, глубина):", th, tv, #l))
for i = 1, math.min(TOP, #l) do
  local c = l[i]
  if c.hid == 0 then break end
  print(string.format("%6d/%-6d | %d/%d %s | %s", c.hid, c.vis, c.adjH, c.adjV, c.deep >= 0 and ("гл." .. c.deep) or "", c.k))
end
if os.getenv("VIS") then
  table.sort(l, function(a, b) return a.vis > b.vis end)
  print("Видимые у пути:")
  for _, c in ipairs(l) do if c.adjV > 0 then print(string.format("%6d/%-6d | %d/%d | %s", c.hid, c.vis, c.adjH, c.adjV, c.k)) end end
end
SV.freeGraph(G); require("ffi").C.free(good)
