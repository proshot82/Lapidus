-- build/l10v/abl.lua файл.lua — несущность: каждый контроль файла (запрет одной ошибки плана) и их сочетания —
-- решаемость, ходов, скрытых (файл и файл+Y), умная обезьяна, двери с кратчайших путей, риск по пути. Только метрики.
local L = dofile("build/l10v/lib.lua")
local def = dofile(arg[1])
local F = dofile("build/l10a/filt10.lua")
local R, V = L.R, L.V
local function all(fs) return function(lvl, st, ns) for _, f in ipairs(fs) do if not f(lvl, st, ns) then return false end end; return true end end
local C = {}
for _, c in ipairs(def.controls) do C[c.name] = c.filter end
local runs = { { "без запретов", nil } }
for _, c in ipairs(def.controls) do runs[#runs+1] = { c.name, c.filter } end
runs[#runs+1] = { "оба «к унитазу»", all({ C["ниппель не к унитазу"], C["переходник не к унитазу"] }) }
runs[#runs+1] = { "оба «к унитазу» + тройник не раньше", all({ C["ниппель не к унитазу"], C["переходник не к унитазу"], C["тройник не раньше переходника"] }) }
runs[#runs+1] = { "все четыре ошибки", all({ C["ниппель не к унитазу"], C["переходник не к унитазу"], C["тройник не раньше переходника"], C["переходник не раньше ниппеля"] }) }
print("запрет | ходов | состояний | скрытых файл | файл+Y | обезьяна | обезьяна(Y) | двери с кратчайших (файл) | риск по пути")
for _, r in ipairs(runs) do
  local S = L.load(def, { filter = r[2] })
  if not S.G.firstWin then print(string.format("  %-38s НЕРЕШАЕМ", r[1])) else
    local lvl = S.lvl
    local tags, sinkQ = {}, nil
    for q, p in ipairs(lvl.pieces) do if p.tag then tags[p.tag] = q end; if p.what == "sink" then sinkQ = q end end
    local srcC = R.idx(lvl, 6, 7)
    local Y = {}
    for i = 1, S.n do if S.flag[i] ~= 2 then local s = S:st(i)
      Y[i] = S.VL.newbie[i] or (not S:live(i) and s.pos[tags.tee] == srcC and s.fixed[tags.tee] and not R.water(lvl, s).wet[sinkQ]) end end
    local m1, m2 = V.measure(S.G, S.good, S.VL.newbie), V.measure(S.G, S.good, Y)
    local sp, ph, mv, bad = S:onShortest(), {}, 0, 0
    for i in pairs(sp) do if S.flag[i] == 0 then
      for e = S.ES[i-1], S.ES[i]-1 do local j = S.E[e]; mv = mv + 1
        if S.flag[j] == 2 or not S:live(j) then bad = bad + 1 end
        if S:hid(j) then ph[S.G.depth[i]] = (ph[S.G.depth[i]] or 0) + 1 end end end end
    local t = {}
    for d = 0, S:opt() - 1 do if ph[d] then t[#t+1] = d .. ":" .. ph[d] end end
    print(string.format("  %-38s %2d  %6d  %5.1f %%  %5.1f %%  %.3f  %.3f  [%s]  %.1f %%", r[1], S:opt(), S.n, m1.hiddenPct, m2.hiddenPct, m1.smart, m2.smart,
      table.concat(t, " "), 100 * bad / math.max(1, mv)))
  end
  S:free()
end
