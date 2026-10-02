-- build/l10v/order.lua файл.lua — где живёт заявленный класс «переходник раньше ниппеля» и прочие состояния по содержимому
-- тоннеля (ряд 7 и колодец): живые / видимые (файл) / скрытые (файл) / скрытые (файл+Y); почему видимы (заморожено/правило).
-- Только метрики.
local L = dofile("build/l10v/lib.lua")
local S = L.load(arg[1])
local R = L.R
local lvl = S.lvl
local tags, sinkQ = {}, nil
for q, p in ipairs(lvl.pieces) do if p.tag then tags[p.tag] = q end; if p.what == "sink" then sinkQ = q end end
local srcC = R.idx(lvl, 6, 7)
local function tun(s)
  -- обезличенные классы содержимого тоннеля (без мест деталей — чтобы не подсказывать финал)
  local n, adp, nip = 0, false, false
  for _, tg in ipairs({ "nip", "adp" }) do local c = s.pos[tags[tg]]
    if c ~= 0 then local x, y = R.xy(lvl, c); if y >= 6 and x <= 6 then n = n + 1; if tg == "adp" then adp = true else nip = true end end end end
  local closed = s.pos[tags.tee] == srcC and s.fixed[tags.tee]
  if closed then return R.water(lvl, s).wet[sinkQ] and "колодец закрыт, мойка мокрая" or ("колодец закрыт, мойка сухая, деталей в тоннеле " .. n) end
  if n == 0 then return "колодец открыт, тоннель пуст" end
  if adp and not nip then return "колодец открыт: переходник упал раньше ниппеля (заявленный класс 4)" end
  return "колодец открыт, деталей в тоннеле " .. n .. (adp and "" or " (только ниппель)")
end
local agg = {}
for i = 1, S.n do if S.flag[i] ~= 2 then local s = S:st(i)
  local k = tun(s)
  local a = agg[k] or { live = 0, vis = 0, hid = 0, hidY = 0 }
  agg[k] = a
  if S:live(i) then a.live = a.live + 1 elseif S.VL.newbie[i] then a.vis = a.vis + 1 else a.hid = a.hid + 1
    if not (s.pos[tags.tee] == srcC and s.fixed[tags.tee] and not R.water(lvl, s).wet[sinkQ]) then a.hidY = a.hidY + 1 end end
end end
local l = {}
for k, a in pairs(agg) do l[#l+1] = { k, a } end
table.sort(l, function(x, y) return (x[2].hid + x[2].vis + x[2].live) > (y[2].hid + y[2].vis + y[2].live) end)
print("содержимое тоннеля | живых | видимых | скрытых (файл) | из них скрытых и при Y")
for _, x in ipairs(l) do local a = x[2]
  print(string.format("  %-62s %6d %6d %6d %6d", x[1], a.live, a.vis, a.hid, a.hidY)) end
S:free()
