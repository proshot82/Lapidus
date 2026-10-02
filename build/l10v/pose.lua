-- build/l10v/pose.lua файл.lua — раздута ли доля скрытых позами Лапидуса: доли скрытых (файл и файл+Y) среди состояний, где
-- тело Лапидуса в колодце/тоннеле (ряды 6–7), и по различным конфигурациям деталей (поза Лапидуса не различается). Только метрики.
local L = dofile("build/l10v/lib.lua")
local S = L.load(arg[1])
local R = L.R
local lvl = S.lvl
local tags, sinkQ = {}, nil
for q, p in ipairs(lvl.pieces) do if p.tag then tags[p.tag] = q end; if p.what == "sink" then sinkQ = q end end
local srcC = R.idx(lvl, 6, 7)
local cnt = { live = { 0, 0 }, hf = { 0, 0 }, hy = { 0, 0 } }
local cfg = { live = {}, hf = {}, hy = {} }
for i = 1, S.n do if S.flag[i] ~= 2 then local s = S:st(i)
  local low = false
  for _, c in ipairs(s.body) do local _, y = R.xy(lvl, c); if y >= 6 then low = true end end
  local k = low and 2 or 1
  local y = S.VL.newbie[i] or (not S:live(i) and s.pos[tags.tee] == srcC and s.fixed[tags.tee] and not R.water(lvl, s).wet[sinkQ])
  local c = S:cfg(s)
  if S:live(i) then cnt.live[k] = cnt.live[k] + 1; cfg.live[c] = true
  elseif not S.VL.newbie[i] then cnt.hf[k] = cnt.hf[k] + 1; cfg.hf[c] = true; if not y then cnt.hy[k] = cnt.hy[k] + 1; cfg.hy[c] = true end end
end end
local function pct(a, b) return 100 * a / math.max(1, a + b) end
print(string.format("Лапидус наверху: живых %d, скрытых файл %d (%.1f %%), Y %d (%.1f %%)", cnt.live[1], cnt.hf[1], pct(cnt.hf[1], cnt.live[1]), cnt.hy[1], pct(cnt.hy[1], cnt.live[1])))
print(string.format("Лапидус в колодце/тоннеле: живых %d, скрытых файл %d, Y %d", cnt.live[2], cnt.hf[2], cnt.hy[2]))
local function n(t) local c = 0; for _ in pairs(t) do c = c + 1 end; return c end
-- по конфигурациям: конфигурация живая, если хоть одна её поза живая
local lv = n(cfg.live)
local hf, hy = 0, 0
for c in pairs(cfg.hf) do if not cfg.live[c] then hf = hf + 1 end end
for c in pairs(cfg.hy) do if not cfg.live[c] then hy = hy + 1 end end
print(string.format("по конфигурациям деталей: живых %d, только-скрытых файл %d (%.1f %%), Y %d (%.1f %%)", lv, hf, pct(hf, lv), hy, pct(hy, lv)))
S:free()
