-- tune.lua шаблон.lua [макс_вывод] — локальная доводка ручного ядра: перебор клеток «?» (стена/пусто)
-- и заранее перечисленных стартов. Шаблон возвращает { grid = {...с '?'}, objects = {...}, starts = { {cells=..., head=...}, ... },
--   length = {a,b}, visibleLoss = f, ablations = {...}, maxQ = число }.
package.path = "./?.lua;" .. package.path
local Q = dofile("build/l6c/b_wall_forever/quick.lua")
local T = dofile(arg[1])
local maxOut = tonumber(arg[2] or 15)
local qs = {}
for y, row in ipairs(T.grid) do for x = 1, #row do if row:sub(x, x) == "?" then qs[#qs + 1] = { x, y } end end end
assert(#qs <= (T.maxQ or 12), "слишком много ?")
local results = {}
local function copyObjs(objs) local o = {} for i, v in ipairs(objs) do o[i] = v end return o end
local total = 0
for mask = 0, 2 ^ #qs - 1 do
  local g = {}
  for y, row in ipairs(T.grid) do g[y] = row end
  for i, c in ipairs(qs) do
    local bit = math.floor(mask / 2 ^ (i - 1)) % 2
    local r = g[c[2]]
    g[c[2]] = r:sub(1, c[1] - 1) .. (bit == 1 and "#" or ".") .. r:sub(c[1] + 1)
  end
  for si, s in ipairs(T.starts) do
    local objs = copyObjs(T.objects)
    objs[#objs + 1] = { kind = "lapidus", cells = s.cells, head = s.head }
    local def = { id = 6, flat = 6, name = "t", length = T.length, pressure = 0, grid = g, objects = objs,
      visibleLoss = T.visibleLoss }
    local okc = true
    for _, c in ipairs(s.cells) do if g[c[2]]:sub(c[1], c[1]) ~= "." then okc = false end end
    for _, o in ipairs(T.objects) do if g[o.at[2]]:sub(o.at[1], o.at[1]) ~= "." then okc = false end end
    if okc then
      total = total + 1
      local ok, m = pcall(Q.metrics, def, 400000)
      if ok and m and not m.err and not m.unsolv and m.nwin == 1 then
        local score = m.hidpct / 10 - math.log10(math.max(m.smart, 0.001)) * 3 + math.min(m.deep, 12) / 4
          - math.max(0, m.walk - 6) * 0.7 + math.min(m.trapSteps, 8) * 0.8 - math.max(0, m.width - 3) * 2
          - (m.opt < 14 and (14 - m.opt) * 0.5 or 0)
        results[#results + 1] = { score = score, m = m, grid = g, si = si }
      end
    end
  end
end
table.sort(results, function(a, b) return a.score > b.score end)
print(string.format("вариантов %d, решаемых с 1 выигрышем %d", total, #results))
for i = 1, math.min(maxOut, #results) do
  local r = results[i]
  print(string.format("#%d score %.1f start %d  %s", i, r.score, r.si, Q.line(r.m)))
  for _, row in ipairs(r.grid) do io.write("   ", row, "\n") end
end
