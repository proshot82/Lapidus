-- классы скрытых тупиков и дверей с кратчайших путей; достижимость «ниппель на Лапидусе при закреплённой муфте» без передачи
local L = dofile("build/l10v/lib.lua")
local R = L.R
local S = L.load("build/p6/fin/final.lua")
local lvl = S.lvl
local function q(tag) for i, p in ipairs(lvl.pieces) do if p.tag == tag then return i end end end
local C, N = q("cpl"), q("nip")
local function onBody(s, c) local below = lvl.nb[c][3]; for _, b in ipairs(s.body) do if b == below then return true end end; return false end
local function where(s, k) local c = s.pos[k]; if c == 0 then return "смыт" end; local x, y = R.xy(lvl, c)
  local z = (y == 6 and x <= 9) and "коридор" or (y <= 3 and "верх" or "середина")
  return z .. (s.fixed[k] and "F" or "") .. (onBody(s, c) and "/наЛ" or "") end
local function key(s)
  local inC = 0; for _, b in ipairs(s.body) do local x, y = R.xy(lvl, b); if y == 6 and x <= 9 then inC = inC + 1 end end
  return "муфта " .. where(s, C) .. "; ниппель " .. where(s, N) .. "; Л в коридоре " .. (inC > 0 and "да" or "нет")
end
local K, D = {}, {}
local hid, live = 0, 0
for i = 1, S.n do if S.flag[i] == 0 then if S:live(i) then live = live + 1 elseif S:hid(i) then hid = hid + 1; local k = key(S:st(i)); K[k] = (K[k] or 0) + 1 end end end
local sp = S:onShortest()
for i in pairs(sp) do if S.flag[i] == 0 then for e = S.ES[i-1], S.ES[i]-1 do local j = S.E[e]
  if S:hid(j) then local k = key(S:st(j)); D[k] = D[k] or {}; D[k][S.G.depth[i]] = true end end end end
print("скрытых", hid, "живых", live)
local l = {}; for k, v in pairs(K) do l[#l+1] = { k, v } end; table.sort(l, function(a, b) return a[2] > b[2] end)
for _, x in ipairs(l) do local ph = {}; for d in pairs(D[x[1]] or {}) do ph[#ph+1] = d end; table.sort(ph)
  if x[2] >= 50 or #ph > 0 then print(string.format("  %5d (%4.1f%%) %s  двери с кратч. на шагах [%s]", x[2], 100 * x[2] / (hid + live), x[1], table.concat(ph, ","))) end end
S:free()
S = L.load("build/p6/fin/final.lua")
local sp2 = S:onShortest()
local pairN = 0
for i = 1, S.n do if S.flag[i] == 0 and S:hid(i) then local s = S:st(i); if s.pos[C] ~= 0 and s.pos[N] ~= 0 and s.asm[C] == s.asm[N] and not s.fixed[C] then pairN = pairN + 1 end end end
print("скрытых со свинченной свободной парой муфта+ниппель:", pairN)
for i in pairs(sp2) do if S.flag[i] == 0 then for e = S.ES[i-1], S.ES[i]-1 do local j = S.E[e]
  if S:hid(j) then local d, sz = S:region(j); local s = S:st(j)
    print(string.format("дверь с шага %d: %s | пара свинчена %s | глубина %d, размер %d, до видимого ≥%s ходов", S.G.depth[i], key(s),
      tostring(s.pos[C] ~= 0 and s.pos[N] ~= 0 and s.asm[C] == s.asm[N]), d, sz, tostring(S:reveal(j)))) end end end end
