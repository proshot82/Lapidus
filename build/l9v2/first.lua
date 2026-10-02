-- build/l9v2/first.lua файл.lua — §5 для g18: старт (допустимых/безопасных ходов), сухая фаза, вероятность схватить деталь
-- всухую раньше подачи воды (случайный игрок, умная обезьяна по разметке файла), мин. ходов от старта до сухого захвата
-- и до воды; куда уходит умная обезьяна (первый вход в тупик по классам) — по разметке файла и файл+Y. Только метрики.
local L = dofile("build/l9v2/lib.lua")
local S = L.load(arg[1])
local R = L.R
local lvl = S.lvl
local tags = {}
for q, p in ipairs(lvl.pieces) do if p.tag then tags[p.tag] = q end end
local sock = R.idx(lvl, 10, 7)
local function grabbed(s)
  for q, p in ipairs(lvl.pieces) do if p.movable and p.tag ~= "nip" and s.pos[q] ~= 0 and s.fixed[q] then return true end end
  return false
end
local dry, wetS, grab = {}, {}, {}
for i = 1, S.n do if S.flag[i] ~= 2 then local s = S:st(i)
  if S:wet(s) then wetS[i] = true elseif grabbed(s) then grab[i] = true else dry[i] = true end end end
local function prob(allowed)
  local p = {}
  for i in pairs(dry) do p[i] = 0 end
  for _ = 1, 5000 do
    local delta = 0
    for i in pairs(dry) do
      local cand = {}
      for e = S.ES[i-1], S.ES[i]-1 do local j = S.E[e]; if S.flag[j] ~= 2 and allowed(i, j) then cand[#cand+1] = j end end
      local v = 0
      if #cand > 0 then
        for _, j in ipairs(cand) do if grab[j] then v = v + 1 elseif wetS[j] then v = v + 0 else v = v + (p[j] or 0) end end
        v = v / #cand
      end
      delta = math.max(delta, math.abs(v - p[i])); p[i] = v
    end
    if delta < 1e-12 then break end
  end
  return p[1]
end
local nd = 0; for _ in pairs(dry) do nd = nd + 1 end
print("сухих состояний без схваченной детали: " .. nd)
print(string.format("случайный игрок: схватит деталь всухую раньше воды с вероятностью %.1f %%", 100 * prob(function() return true end)))
print(string.format("умная обезьяна (файл): %.1f %%", 100 * prob(function(i, j) return S.flag[j] == 1 or not S.VL.newbie[j] end)))
-- BFS от старта
local d, q, h = { [1] = 0 }, { 1 }, 1
local firstGrab, firstWet
while h <= #q do local u = q[h]; h = h + 1
  if grab[u] and not firstGrab then firstGrab = d[u] end
  if wetS[u] and not firstWet then firstWet = d[u] end
  if not wetS[u] and not grab[u] then
    for e = S.ES[u-1], S.ES[u]-1 do local v = S.E[e]; if S.flag[v] ~= 2 and d[v] == nil then d[v] = d[u] + 1; q[#q+1] = v end end end end
print(string.format("мин. ходов от старта: до воды %s, до сухого захвата детали (не намочив сеть) %s", tostring(firstWet), tostring(firstGrab)))
local legal, safe = 0, 0
for e = S.ES[0], S.ES[1]-1 do legal = legal + 1; if S:live(S.E[e]) then safe = safe + 1 end end
print(string.format("старт: допустимых ходов %d, из них не губят %d", legal, safe))
-- первая встреча с гребёнкой: мин. ходов от старта до состояния, где подвижная деталь (не ниппель) в столбе/над гребнем
-- или касается выхода гребёнки
local F = dofile("build/l9a/filt.lua")
local dd, qq, hh = { [1] = 0 }, { 1 }, 1
local meet
while hh <= #qq do local u = qq[hh]; hh = hh + 1
  local s = S:st(u)
  local hit = false
  for qn, p in ipairs(lvl.pieces) do if p.movable and p.tag ~= "nip" and s.pos[qn] ~= 0 then
    local x, y = R.xy(lvl, s.pos[qn]); if (x == 7 or x == 8) and y <= 6 and y >= 3 then hit = true end end end
  if hit then meet = { dd[u], S:wet(s), S:live(u) }; break end
  for e = S.ES[u-1], S.ES[u]-1 do local v = S.E[e]; if S.flag[v] ~= 2 and dd[v] == nil then dd[v] = dd[u] + 1; qq[#qq+1] = v end end end
if meet then print(string.format("первая встреча детали с гребёнкой (деталь над выходами m1/m2): мин. %d ходов, сеть %s, состояние %s", meet[1], meet[2] and "мокрая" or "СУХАЯ", meet[3] and "живое" or "проигранное")) end
-- судьба умной обезьяны
local function fate(lost, label)
  local function key(i) local s = S:st(i); return (S:wet(s) and "мокро " or "сухо ") .. S:fixedSig(s) end
  local T = 5 * S:opt()
  local p, ok, first = { [1] = 1.0 }, 0, {}
  for _ = 1, T do
    local np = {}
    for i, pr in pairs(p) do
      local cand = {}
      for e = S.ES[i-1], S.ES[i]-1 do local j = S.E[e]
        if S.flag[j] == 1 then cand[#cand+1] = j elseif S.flag[j] ~= 2 and not lost[j] then cand[#cand+1] = j end end
      if #cand == 0 then np[i] = (np[i] or 0) + pr else
        local share = pr / #cand
        for _, j in ipairs(cand) do
          if S.flag[j] == 1 then ok = ok + share
          elseif S:live(i) and not S:live(j) then local k = key(j); first[k] = (first[k] or 0) + share; np[j] = (np[j] or 0) + share
          else np[j] = (np[j] or 0) + share end
        end
      end
    end
    p = np
  end
  local liveP = 0
  for i, pr in pairs(p) do if S:live(i) then liveP = liveP + pr end end
  print(string.format("%s: за %d ходов выигрыш %.4f %%, ещё живы %.1f %%; первый вход в скрытый тупик по классам:", label, T, 100 * ok, 100 * liveP))
  local l = {}
  for k, v in pairs(first) do l[#l+1] = { k, v } end
  table.sort(l, function(a, b) return a[2] > b[2] end)
  for i = 1, math.min(8, #l) do print(string.format("  %6.2f %%  %s", 100 * l[i][2], l[i][1])) end
end
fate(S.VL.newbie, "обезьяна по разметке файла")
local Y = {}
for i = 1, S.n do if S.flag[i] ~= 2 then local s = S:st(i)
  Y[i] = S.VL.newbie[i] or (not S:live(i) and s.pos[tags.tee] ~= 0 and s.fixed[tags.tee] and s.pos[tags.tee] ~= sock) end end
fate(Y, "обезьяна по разметке файл+Y")
S:free()
