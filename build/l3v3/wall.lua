-- build/l3v3/wall.lua [файл] — замуровка по клеткам: каждую свободную клетку (без деталей и Лапидуса) — стеной;
-- решаемость, ходов, абляции, скрытые, двери. Классы: несущая / приманка (через клетку проходит дверь) / мёртвая.
-- Затем замуровать все мёртвые разом.
local L = dofile("build/l3v3/lib.lua")
local path = arg[1] or "levels/03.lua"
local base = dofile(path)
local ctx = L.load(path, 4)
local G, lvl = ctx.G, ctx.lvl
-- клетки дверей: клетки, которые занимает ход живое→скрытое (новые клетки конца и мыла в целевом состоянии, старые — в исходном)
local doorCells = {}
for i = 1, G.n do
  if G.flag[i] == 0 and ctx.good[i] == 1 then
    for _, j in ipairs(L.edges(ctx, i)) do
      if L.status(ctx, j) == "hid" then
        local si, sj = ctx.sts[i], ctx.sts[j]
        local occI = {}
        for _, c in ipairs(si.body) do occI[c] = true end
        for _, c in ipairs(sj.body) do if not occI[c] then doorCells[c] = true end end
        for q = 1, #si.pos do if si.pos[q] ~= sj.pos[q] then if si.pos[q] ~= 0 then doorCells[si.pos[q]] = true end; if sj.pos[q] ~= 0 then doorCells[sj.pos[q]] = true end end end
      end
    end
  end
end
local dl = {}
for c in pairs(doorCells) do local x, y = L.xy(ctx, c); dl[#dl + 1] = string.format("(%d,%d)", x, y) end
table.sort(dl)
print("клетки, через которые проходят двери: " .. table.concat(dl, " "))
local baseM = L.metrics(base)
print("база: " .. L.fmt(baseM))
L.free(ctx)
local occ = {}
for _, o in ipairs(base.objects) do
  if o.at then occ[o.at[1] .. "," .. o.at[2]] = true end
  if o.cells then for _, c in ipairs(o.cells) do occ[c[1] .. "," .. c[2]] = true end end
end
local dead, decoy, bearing = {}, {}, {}
for y = 1, #base.grid do
  for x = 1, #base.grid[y] do
    if base.grid[y]:sub(x, x) == "." and not occ[x .. "," .. y] then
      local d = L.brick(base, { { x, y } })
      d.ablations = base.ablations
      local r = L.metrics(d)
      local abl = ""
      if r.solvable then
        local a = L.SV.ablations(d, { cap = 3000000 })
        local s = {}
        for _, e in ipairs(a) do if e.solvable ~= false then s[#s + 1] = e.name end end
        abl = #s > 0 and (" | абляции РЕШАЕМЫ: " .. table.concat(s, ", ")) or " | абляции все нерешаемы"
      end
      local c = (y - 1) * lvl.W + x
      local cls
      if not r.solvable or r.opt ~= baseM.opt or r.nwin ~= baseM.nwin or abl:find("РЕШАЕМЫ") then cls = "НЕСУЩАЯ"; bearing[#bearing + 1] = { x, y }
      elseif doorCells[c] then cls = "приманка"; decoy[#decoy + 1] = { x, y }
      else cls = "мёртвая"; dead[#dead + 1] = { x, y } end
      print(string.format("(%2d,%d) %-9s %s%s", x, y, cls, L.fmt(r), abl))
      io.stdout:flush()
    end
  end
end
local function lst(t) local s = {} for _, c in ipairs(t) do s[#s + 1] = string.format("(%d,%d)", c[1], c[2]) end return table.concat(s, " ") end
print("\nнесущие: " .. lst(bearing))
print("приманки: " .. lst(decoy))
print("мёртвые: " .. (#dead > 0 and lst(dead) or "нет"))
if #dead > 0 then
  local d = L.brick(base, dead); d.ablations = base.ablations
  print("ПОСЛЕ ЗАМУРОВКИ мёртвых: " .. L.fmt(L.metrics(d)))
  if #decoy > 0 then
    local all = {} for _, c in ipairs(dead) do all[#all + 1] = c end for _, c in ipairs(decoy) do all[#all + 1] = c end
    local d2 = L.brick(base, all); d2.ablations = base.ablations
    print("после замуровки мёртвых и приманок (справочно): " .. L.fmt(L.metrics(d2)))
  end
end
