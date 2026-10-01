-- build/l9v/fate.lua файл.lua [W] — куда уходит «умная обезьяна» (не делает видимо проигрышных ходов) за одну попытку
-- 5×опт ходов: доля выигрыша, ещё живых и первого входа в каждый класс тупиков (вода | закреплённые детали).
-- С аргументом W — обезьяна знает правила W+T+S (build/l9v/alt.lua). Только метрики.
local L = dofile("build/l9v/lib.lua")
local S = L.load(arg[1])
local R = L.R
local lvl, W = S.lvl, S.lvl.W
local function idx(x, y) return (y - 1) * W + x end
local tags = {}
for q, p in ipairs(lvl.pieces) do if p.tag then tags[p.tag] = q end end
local function occ(s) local t = {} for q = 1, #s.pos do if s.pos[q] ~= 0 then t[s.pos[q]] = q end end return t end
local function extra(s)
  local o = occ(s)
  for q, p in ipairs(lvl.pieces) do if p.movable and s.pos[q] ~= 0 and s.fixed[q] then
    for d = 1, 4 do if p.ports[d] then
      local t = lvl.nb[s.pos[q]][d]
      if t == 0 or lvl.cell[t] == R.WALL then return true end
      local r = o[t]
      if r and s.fixed[r] and not R.match(p.ports[d], lvl.pieces[r].ports[R.OPP[d]]) then return true end
    end end end end
  local q9 = o[idx(9, 7)]
  if q9 and s.fixed[q9] and lvl.pieces[q9].ports[R.RIGHT] ~= "V" then return true end
  local bodyMinX = 99
  for _, c in ipairs(s.body) do local x, y = R.xy(lvl, c)
    if (y == 5 and x <= 5) or (x == 2 and (y == 6 or y == 7)) or y == 8 then bodyMinX = math.min(bodyMinX, (y == 5) and x or 0) end end
  for _, tg in ipairs({ "tee", "plug" }) do local q = tags[tg]
    if q and s.pos[q] ~= 0 and not s.fixed[q] then
      local x, y = R.xy(lvl, s.pos[q])
      local stacked = (x == 6 and y == 4 and o[idx(6, 5)] and not s.fixed[o[idx(6, 5)]])
      if ((y == 5 and x <= 6) or stacked) and not (bodyMinX < (stacked and 6 or x)) then return true end
    end end
  return false
end
local lost = S.VL.newbie
if arg[2] == "W" then
  lost = {}
  for i = 1, S.n do if S.flag[i] ~= 2 then lost[i] = S.VL.newbie[i] or (not S:live(i) and extra(S:st(i))) end end
end
local function key(i) local s = S:st(i); return (S:wet(s) and "мокро " or "сухо ") .. S:fixedSig(s) end
local opt = S:opt()
local T = 5 * opt
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
print(string.format("%s: за %d ходов выигрыш %.4f %%, ещё живы %.1f %%; первый вход в тупик по классам:", arg[2] == "W" and "обезьяна знает W+T+S" or "обезьяна по линейке", T, 100 * ok, 100 * liveP))
local l = {}
for k, v in pairs(first) do l[#l+1] = { k, v } end
table.sort(l, function(a, b) return a[2] > b[2] end)
for i = 1, math.min(10, #l) do print(string.format("  %5.1f %%  %s", 100 * l[i][2], l[i][1])) end
S:free()
