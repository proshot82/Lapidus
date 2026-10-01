-- build/l9v/persist.lua файл.lua — стойкость ошибок как естественное продолжение ложного плана (а не максимум блуждания).
-- Для каждой двери с кратчайших путей (и в 1–2 ходах от них) — мин. ходов по скрытым до «момента правды»:
--   ошибка «собрать всухую»: до намокания сети (ниппель в устье) — течь в стену видна;
--   ошибка «заглушка в ближний фонтан»: до попытки ложного плана — ноги прикручены к ванне при полной длине и голова
--     в столбе дальнего фонтана (натянут), или голова прикручена к дальнему фонтану при полной длине;
--   ошибка «тройник в дальний фонтан»: до намокания/течи — сразу (тройник уже мокрый) → считаем ходы до видимого по линейке.
-- Плюс минимум до видимого по линейке и по линейке+W+T+S. Только метрики.
local L = dofile("build/l9v/lib.lua")
local S = L.load(arg[1])
local R = L.R
local lvl, W = S.lvl, S.lvl.W
local function idx(x, y) return (y - 1) * W + x end
local tags = {}
for q, p in ipairs(lvl.pieces) do if p.tag then tags[p.tag] = q end end
local bathQ, m2Q, m1Q
for q, p in ipairs(lvl.pieces) do if p.what == "bath" then bathQ = q elseif p.tag == "m2" then m2Q = q elseif p.tag == "m1" then m1Q = q end end
local sp = S:onShortest()
local off, ph, q, h = {}, {}, {}, 1
for i = 1, S.n do if sp[i] then off[i] = 0; ph[i] = S.G.depth[i]; q[#q+1] = i end end
while h <= #q do local u = q[h]; h = h + 1
  for e = S.ES[u-1], S.ES[u]-1 do local v = S.E[e]
    if S:live(v) and off[v] == nil then off[v] = off[u] + 1; ph[v] = ph[u]; q[#q+1] = v end end end
local function truth(s, kind)
  if kind == "dry" then return S:wet(s) end
  -- попытка ложного плана: ноги в ванне при полной длине, голова в столбе дальнего фонтана (натянут),
  -- или голова прикручена к дальнему фонтану при полной длине (ноги до ванны не достают)
  local piece = R.occupancy(s)
  local hq = R.endScrew(lvl, s, piece, "head")
  local fq = R.endScrew(lvl, s, piece, "heel")
  local hx, hy = R.xy(lvl, s.body[#s.body])
  if #s.body == lvl.Lmax and ((fq == bathQ and hx == 8 and hy >= 4) or hq == m2Q) then return true end
  return false
end
local function bfs(j, pred)
  local d, qq, hh = { [j] = 0 }, { j }, 1
  if pred(S:st(j)) then return 0 end
  while hh <= #qq do local u = qq[hh]; hh = hh + 1
    for e = S.ES[u-1], S.ES[u]-1 do local v = S.E[e]
      if S.flag[v] == 0 and not S:live(v) and d[v] == nil then
        d[v] = d[u] + 1
        if pred(S:st(v)) then return d[v] end
        qq[#qq+1] = v end end end
  return nil
end
print("дверь (шаг пути, удаление) | класс | до «момента правды» естественного продолжения | до видимого по линейке | глубина")
for i = 1, S.n do if S.flag[i] == 0 and S:live(i) and off[i] and off[i] <= 2 then
  for e = S.ES[i-1], S.ES[i]-1 do local j = S.E[e]
    if S:hid(j) then
      local s = S:st(j)
      local wet = S:wet(s)
      local md = S:region(j)
      local tt
      if not wet then
        local t = bfs(j, function(x) return truth(x, "dry") end)
        tt = "до воды " .. (t and tostring(t) or "не наступает")
      else
        local ta = bfs(j, function(x) local pc = R.occupancy(x); return #x.body == lvl.Lmax and R.endScrew(lvl, x, pc, "head") == m2Q end)
        local tb = bfs(j, function(x) local pc = R.occupancy(x); local hx, hy = R.xy(lvl, x.body[#x.body])
          return #x.body == lvl.Lmax and R.endScrew(lvl, x, pc, "heel") == bathQ and hx == 8 and hy >= 4 end)
        tt = "голова на дальний фонтан " .. (ta and tostring(ta) or "—") .. " / ноги в ванне, голова над дальним " .. (tb and tostring(tb) or "—")
      end
      print(string.format("  шаг %2d, удаление %d | %-30s | %s | %s | %d", ph[i], off[i], (wet and "мокро " or "сухо ") .. S:fixedSig(s),
        tt, tostring(S:reveal(j) or "никогда"), md))
    end end end end
-- для сравнения: на правильном пути — через сколько ходов после шага 16 ноги прикручиваются к ванне
S:free()
