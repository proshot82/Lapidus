-- build/l4v/an2.lua — входы в скрытые тупики с кратчайшего пути: шаг, класс, глубина (без ходов).
-- luajit build/l4v/an2.lua [файл]
arg = { arg[1] or "build/l4v/k29_ruleid.lua", "4" }
dofile("build/l4v/an.lua")
local R = require("core.rules")
local A = AN
local G, good, VL, sts, lvl = A.G, A.good, A.VL, A.sts, A.lvl
local qc, qn, B, T = A.qc, A.qn, A.B, A.T
local ES, E = G.eStart.p, G.edges.p
local function cls(st)
  if st.fixed[qc] and st.pos[qc] ~= B then return "К1" end
  if st.fixed[qn] and st.pos[qn] ~= T then return "К2" end
  if not st.fixed[qc] and not st.fixed[qn] and st.asm[qc] == st.asm[qn] then return "К3" end
  if not st.fixed[qc] and not st.fixed[qn] then return "К5" end
  return "проч"
end
local hidden = {}
for i = 1, G.n do if G.flag[i] ~= 2 and good[i] ~= 1 and not VL.newbie[i] then hidden[i] = true end end
local path, x = {}, G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
local function depthFrom(j, allowed)
  local d, q, h, maxd = { [j] = 0 }, { j }, 1, 0
  while h <= #q do
    local u = q[h]; h = h + 1
    for e = ES[u - 1], ES[u] - 1 do
      local v = E[e]
      if hidden[v] and (not allowed or allowed(v)) and d[v] == nil then d[v] = d[u] + 1; if d[v] > maxd then maxd = d[v] end; q[#q + 1] = v end
    end
  end
  return maxd, #q
end
local function cfg(st)
  local t = {}
  for _, q in ipairs({ qc, qn }) do local xx, yy = R.xy(lvl, st.pos[q]); t[#t + 1] = string.format("%s(%d,%d)%s", lvl.pieces[q].tag, xx, yy, st.fixed[q] and "F" or "") end
  return table.concat(t, " ")
end
print("входы в скрытое с кратчайшего пути: шаг | класс | конфигурация деталей | глубина / размер области")
local seenK = {}
for k = 1, #path - 1 do
  local s = path[k]
  for e = ES[s - 1], ES[s] - 1 do
    local j = E[e]
    if hidden[j] then
      local st = sts[j]
      local c = cls(st)
      local d, sz = depthFrom(j)
      local key = k .. c .. cfg(st)
      if not seenK[key] then seenK[key] = true
        print(string.format("  шаг %2d | %s | %s | глубина %d, область %d", k - 1, c, cfg(st), d, sz)) end
    end
  end
end
-- безопасных (живых) ходов и вынужденные ходы по пути
local seq, forced, maxForced = {}, 0, 0
for k = 1, #path - 1 do
  local s, safe, tot = path[k], 0, 0
  for e = ES[s - 1], ES[s] - 1 do
    local j = E[e]; tot = tot + 1
    if good[j] == 1 then safe = safe + 1 end
  end
  -- «правдоподобных» ходов: не в видимый проигрыш (новичок) и не смыло
  local plaus = 0
  for e = ES[s - 1], ES[s] - 1 do local j = E[e]; if G.flag[j] ~= 2 and not VL.newbie[j] then plaus = plaus + 1 end end
  seq[#seq + 1] = string.format("%d/%d/%d", safe, plaus, tot)
  if safe == 1 then forced = forced + 1; if forced > maxForced then maxForced = forced end else forced = 0 end
end
print("по шагам пути (живых/не видимо проигрышных/всего): " .. table.concat(seq, " "))
print("макс. подряд шагов с единственным живым ходом: " .. maxForced)
-- класс-судьбы: для каждого класса — ближайший шаг пути, откуда в него входят (в 1 ход), и глубина в классе
for _, c in ipairs({ "К1", "К2", "К3", "К5" }) do
  local best, bestD = nil, 0
  for k = 1, #path - 1 do
    local s = path[k]
    for e = ES[s - 1], ES[s] - 1 do
      local j = E[e]
      if hidden[j] and cls(sts[j]) == c then
        local d = depthFrom(j)
        if not best then best = k - 1 end
        if d > bestD then bestD = d end
      end
    end
  end
  print(string.format("класс %s: первый вход с пути на шаге %s, макс. глубина скрытой области от входа %d", c, tostring(best), bestD))
end
