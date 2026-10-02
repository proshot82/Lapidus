-- build/l10v/persist2.lua файл.lua — стойкость ошибок «деталь к унитазу» как естественное продолжение ложного плана
-- (разметка файл+Y): от дверей с кратчайших путей — по скрытым состояниям мин. ходов до вехи «первая оставшаяся деталь
-- упала в колодец/тоннель» (с аргументом тег — именно эта деталь, тройник не в тоннеле) и скрыто ли состояние на вехе; затем от вехи — ходов до видимого. Для сравнения: на верном пути
-- от того же шага до первого падения детали в тоннель. Только метрики.
local L = dofile("build/l10v/lib.lua")
local S = L.load(arg[1])
local R = L.R
local lvl = S.lvl
local tags, sinkQ = {}, nil
for q, p in ipairs(lvl.pieces) do if p.tag then tags[p.tag] = q end; if p.what == "sink" then sinkQ = q end end
local toilet, srcC = R.idx(lvl, 10, 5), R.idx(lvl, 6, 7)
local Y = {}
for i = 1, S.n do if S.flag[i] ~= 2 then local s = S:st(i)
  Y[i] = S.VL.newbie[i] or (not S:live(i) and s.pos[tags.tee] == srcC and s.fixed[tags.tee] and not R.water(lvl, s).wet[sinkQ]) end end
local function inTun(s, tg) local c = s.pos[tags[tg]]; if c == 0 then return false end; local x, y = R.xy(lvl, c); return y >= 6 and x <= 6 end
local function anyTun(s) return inTun(s, "nip") or inTun(s, "adp") or inTun(s, "tee") end
local want = arg[2] -- если задан тег: веха — падение именно этой детали в тоннель (тройник при этом не в тоннеле)
local function mile(s) if want then return inTun(s, want) and not inTun(s, "tee") end; return anyTun(s) end
local path, x = {}, S.G.firstWin
while x ~= 1 do table.insert(path, 1, x); x = S.G.parent[x] end
table.insert(path, 1, 1)
local firstDrop
for k, id in ipairs(path) do if anyTun(S:st(id)) then firstDrop = k - 1 break end end
print(string.format("верный путь: первая деталь в тоннеле на шаге %d", firstDrop))
local sp = S:onShortest()
print("шаг | класс | до первой детали в тоннеле по скрытым (веха скрыта?) | от вехи до видимого (мин / глубина скрытой области) | верным путём до первого падения")
for i in pairs(sp) do if S.flag[i] == 0 and S:live(i) then
  for e = S.ES[i-1], S.ES[i]-1 do local j = S.E[e]
    if S:hid(j, Y) then
      local s = S:st(j)
      local cls = (s.fixed[tags.nip] and s.pos[tags.nip] == toilet) and "ниппель к унитазу" or ((s.fixed[tags.adp] and s.pos[tags.adp] == toilet) and "переходник к унитазу" or "тройник на теле")
      -- BFS по скрытым до первой вехи; собрать все вехи на минимальной глубине
      local d, q, h, best, hidAt, visAt = { [j] = 0 }, { j }, 1, nil, 0, 0
      local mins, deeps = 99, -1
      while h <= #q do local u = q[h]; h = h + 1
        if best and d[u] >= best then break end
        for e2 = S.ES[u-1], S.ES[u]-1 do local v = S.E[e2]
          if S.flag[v] == 0 and not S:live(v) and d[v] == nil then
            d[v] = d[u] + 1
            if mile(S:st(v)) then best = d[v]
              if Y[v] then visAt = visAt + 1 else hidAt = hidAt + 1
                local r = S:reveal(v, Y) or 0; if r < mins then mins = r end
                local md = S:region(v, Y); if md > deeps then deeps = md end end
            elseif not Y[v] then q[#q+1] = v end end end end
      print(string.format("  шаг %2d | %-22s | %s (скрытых вех %d, видимых %d) | %s / %s | %d", S.G.depth[i], cls, tostring(best or "—"), hidAt, visAt,
        mins < 99 and tostring(mins) or "—", deeps >= 0 and tostring(deeps) or "—", firstDrop - S.G.depth[i]))
    end end end end
S:free()
