-- build/l10v/region.lua файл.lua — что происходит внутри скрытой области после каждой двери с кратчайших путей (файл+Y):
-- конфигурации деталей в области (без позы Лапидуса) и чем она кончается (на границе — видимые: причина по линейке/Y).
-- Только конфигурации деталей, без ходов.
local L = dofile("build/l10v/lib.lua")
local S = L.load(arg[1])
local R = L.R
local lvl = S.lvl
local tags, sinkQ = {}, nil
for q, p in ipairs(lvl.pieces) do if p.tag then tags[p.tag] = q end; if p.what == "sink" then sinkQ = q end end
local srcC = R.idx(lvl, 6, 7)
local Y, why = {}, {}
for i = 1, S.n do if S.flag[i] ~= 2 then local s = S:st(i)
  local y = (not S:live(i) and s.pos[tags.tee] == srcC and s.fixed[tags.tee] and not R.water(lvl, s).wet[sinkQ])
  Y[i] = S.VL.newbie[i] or y
  why[i] = S.VL.newbie[i] and "линейка" or (y and "Y мойка отрезана" or nil) end end
local sp = S:onShortest()
local seen = {}
for i in pairs(sp) do if S.flag[i] == 0 and S:live(i) then
  for e = S.ES[i-1], S.ES[i]-1 do local j = S.E[e]
    if S:hid(j, Y) and not seen[j] then seen[j] = true
      local d, q, h = { [j] = 0 }, { j }, 1
      local cfgs, front = {}, {}
      while h <= #q do local u = q[h]; h = h + 1
        local c = S:cfg(S:st(u)); cfgs[c] = math.min(cfgs[c] or 99, d[u])
        for e2 = S.ES[u-1], S.ES[u]-1 do local v = S.E[e2]
          if d[v] == nil then d[v] = d[u] + 1
            if S.flag[v] == 0 and not S:live(v) and not Y[v] then q[#q+1] = v
            elseif S.flag[v] == 0 and Y[v] then local k = why[v] .. ": " .. S:cfg(S:st(v)); front[k] = math.min(front[k] or 99, d[v]) end end end end
      print(string.format("== дверь с шага %d: скрытых в области %d", S.G.depth[i], #q))
      local l = {}
      for c, dd in pairs(cfgs) do l[#l+1] = { c, dd } end
      table.sort(l, function(a, b) return a[2] < b[2] end)
      for _, x in ipairs(l) do print(string.format("   внутри (с хода %d): %s", x[2], x[1])) end
      l = {}
      for c, dd in pairs(front) do l[#l+1] = { c, dd } end
      table.sort(l, function(a, b) return a[2] < b[2] end)
      for _, x in ipairs(l) do print(string.format("   граница (ход %d): %s", x[2], x[1])) end
    end end end end
S:free()
