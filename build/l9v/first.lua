-- build/l9v/first.lua файл.lua — §5 «первая встреча безопасна»: вероятность, что игрок до подачи воды уронит деталь
-- на сухую гребёнку (класс «сухо, деталь закреплена»), для трёх моделей игрока: случайный (все ходы равновероятны),
-- «умная обезьяна» (не делает видимо проигрышных ходов по линейке) и «знающий W» (не делает ходов, после которых
-- резьба смотрит в стену). Поглощение — «сеть намокла» или «деталь схвачена всухую». Только числа.
local L = dofile("build/l9v/lib.lua")
local S = L.load(arg[1])
local R = L.R
local lvl = S.lvl
local function grabbed(s)
  for q, p in ipairs(lvl.pieces) do if p.movable and p.tag ~= "nip" and s.pos[q] ~= 0 and s.fixed[q] then return true end end
  return false
end
local dry, wetS, grab = {}, {}, {}
for i = 1, S.n do if S.flag[i] ~= 2 then local s = S:st(i)
  if S:wet(s) then wetS[i] = true elseif grabbed(s) then grab[i] = true else dry[i] = true end end end
local function prob(allowed)
  -- итерация значения: p[i] = вероятность «схвачено» раньше «намокло»
  local p = {}
  for i in pairs(dry) do p[i] = 0 end
  for _ = 1, 2000 do
    local delta = 0
    for i in pairs(dry) do
      local cand = {}
      for e = S.ES[i-1], S.ES[i]-1 do local j = S.E[e]; if allowed(i, j) then cand[#cand+1] = j end end
      local v = 0
      if #cand > 0 then
        for _, j in ipairs(cand) do
          if grab[j] then v = v + 1 elseif wetS[j] then v = v + 0 else v = v + (p[j] or 0) end end
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
print(string.format("случайный игрок: схватит деталь всухую раньше, чем даст воду, с вероятностью %.1f %%", 100 * prob(function(i, j) return true end)))
print(string.format("умная обезьяна (линейка): %.1f %%", 100 * prob(function(i, j) return S.flag[j] == 1 or not S.VL.newbie[j] end)))
local legal, safe = 0, 0
for e = S.ES[0], S.ES[1]-1 do legal = legal + 1; if S:live(S.E[e]) then safe = safe + 1 end end
print(string.format("старт: допустимых ходов %d, из них не губят %d", legal, safe))
S:free()
