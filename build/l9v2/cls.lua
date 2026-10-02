-- build/l9v2/cls.lua файл.lua [карман] — классы скрытых тупиков (мерка новичка с правилами файла) по закреплённым деталям
-- и воде: размер, двери из живых, с кратчайших путей (фазы), глубина, мин. ходов до видимого. Только метрики.
local L = dofile("build/l9v2/lib.lua")
local S = L.load(arg[1], { pocket = tonumber(arg[2] or 4) })
local R = L.R
local n, ES, E = S.n, S.ES, S.E
local sp = S:onShortest()
local live, hidN, visN = 0, 0, 0
local cls = {}
local function key(s) return (S:wet(s) and "мокро | " or "сухо  | ") .. S:fixedSig(s) end
for i = 1, n do if S.flag[i] ~= 2 then
  if S:live(i) then live = live + 1
  elseif S.VL.newbie[i] then visN = visN + 1
  else hidN = hidN + 1
    local k = key(S:st(i))
    local c = cls[k] or { size = 0, doors = 0, spDoors = 0, phs = {}, deep = 0, rmin = 99, rmax = -1, exp = 0 }
    cls[k] = c
    c.size = c.size + 1
    if not S.VL.expert[i] then c.exp = c.exp + 1 end
  end end end
for i = 1, n do if S.flag[i] == 0 and S:live(i) then
  for e = ES[i-1], ES[i]-1 do local j = E[e]
    if S:hid(j) then
      local c = cls[key(S:st(j))]
      c.doors = c.doors + 1
      if sp[i] then
        c.spDoors = c.spDoors + 1
        c.phs[S.G.depth[i]] = true
        local md = S:region(j); if md > c.deep then c.deep = md end
        local r = S:reveal(j) or 99
        if r < c.rmin then c.rmin = r end; if r > c.rmax then c.rmax = r end
      end
    end end end end
print(string.format("карман %d: живых %d, видимых %d, скрытых %d → скрытых %.1f %%", tonumber(arg[2] or 4), live, visN, hidN, 100 * hidN / (hidN + live)))
local l = {}
for k, c in pairs(cls) do l[#l+1] = { k, c } end
table.sort(l, function(a, b) return a[2].size > b[2].size end)
print("класс | состояний (% от скрытых+живых) | скрыты и знатоку | дверей из живых | с кратчайших [фазы] | глубина | до видимого")
for _, x in ipairs(l) do local k, c = x[1], x[2]
  local ph = {}
  for p in pairs(c.phs) do ph[#ph+1] = p end
  table.sort(ph)
  print(string.format("  %-44s %5d (%4.1f %%) знат %4d  дв %4d  кр %2d [%s]  гл %2s  вскр %s", k, c.size, 100 * c.size / (hidN + live), c.exp, c.doors, c.spDoors,
    table.concat(ph, ","), c.spDoors > 0 and tostring(c.deep) or "-", c.spDoors > 0 and (c.rmin .. "–" .. c.rmax) or "-"))
end
S:free()
