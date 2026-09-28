-- hidshow.lua файл.lua [N] — показать несколько СКРЫТЫХ тупиков (кадры состояний, только вывод инструмента, для себя),
-- по одному на «вход» из живой области (живое → скрытое), с минимальной глубиной.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local function lost(st)
  for q, p in ipairs(lvl.pieces) do if p.movable and st.pos[q] == 0 then return true end end
  return def.visibleLoss and def.visibleLoss(lvl, st) or false
end
local SYM = { source = "S", fixture = "F", stub = "T", pipe = "=", fitting = "b", porcelain = "P" }
local function show(s)
  local rows = {}
  for y = 1, lvl.H do rows[y] = {} for x = 1, lvl.W do local c = lvl.cell[(y-1)*lvl.W+x]; rows[y][x] = c == 1 and "#" or (c == 2 and "~" or ".") end end
  for q, pp in ipairs(lvl.pieces) do if s.pos[q] ~= 0 then local x, y = R.xy(lvl, s.pos[q]); local ch = (pp.tag and pp.tag:sub(1,1)) or SYM[pp.kind]; if pp.movable then ch = s.fixed[q] and ch:upper() or ch:lower() else ch = SYM[pp.kind] end; rows[y][x] = ch end end
  if not s.dead then for i, c in ipairs(s.body) do local x, y = R.xy(lvl, c); rows[y][x] = (i == #s.body) and "H" or ((i == 1) and "f" or "o") end end
  local out = {}
  for y = 1, lvl.H do out[#out+1] = table.concat(rows[y]) end
  return out
end
local entries = {}
for i = 1, G.n do
  if good[i] == 1 then
    for e = G.eStart.p[i - 1], G.eStart.p[i] - 1 do
      local j = G.edges.p[e]
      if G.flag[j] ~= 2 and good[j] ~= 1 then
        local sj = R.decode(lvl, G.keys[j])
        if not lost(sj) then entries[#entries+1] = { i = i, j = j, d = G.depth[i] } end
      end
    end
  end
end
table.sort(entries, function(a, b) return a.d < b.d end)
local N = tonumber(arg[2] or 6)
local frames = {}
local seen = {}
for _, en in ipairs(entries) do
  if #frames >= 2 * N then break end
  if not seen[en.j] then seen[en.j] = true
    local a = show(R.decode(lvl, G.keys[en.i])); local b = show(R.decode(lvl, G.keys[en.j]))
    table.insert(a, 1, "жив d" .. en.d); table.insert(b, 1, "-> тупик")
    frames[#frames+1] = a; frames[#frames+1] = b
  end
end
print("входов в скрытые тупики:", #entries)
local per = math.max(2, math.floor(120 / (lvl.W + 2)))
for k = 1, #frames, per do
  for line = 1, lvl.H + 1 do
    local parts = {}
    for j = k, math.min(k + per - 1, #frames) do parts[#parts+1] = string.format("%-" .. (lvl.W + 2) .. "s", frames[j][line] or "") end
    print(table.concat(parts, ""))
  end
  print()
end
SV.freeGraph(G); require("ffi").C.free(good)
