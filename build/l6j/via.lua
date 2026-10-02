-- build/l6j/via.lua файл.lua "cpl(5,7) nip(5,6)" [frames] — кратчайший путь к победе ЧЕРЕЗ состояние с данной
-- конфигурацией деталей: сначала кратчайший путь из старта в такую конфигурацию (живую), потом из неё к победе.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local def = dofile(arg[1])
local lvl = R.compile(def)
local G = SV.explore(lvl, 3000000)
local good = SV.goodSet(G)
local want = arg[2]
local function cfg(st)
  local t = {}
  for q, p in ipairs(lvl.pieces) do if p.movable then
    if st.pos[q] == 0 then t[#t+1] = (p.tag or p.what) .. "=смыт" else
      local x, y = R.xy(lvl, st.pos[q]); t[#t+1] = string.format("%s(%d,%d)%s", p.tag or p.what, x, y, st.fixed[q] and "F" or "") end end end
  return table.concat(t, " ")
end
local via
for i = 1, G.n do
  if G.flag[i] ~= 2 and good[i] == 1 and cfg(R.decode(lvl, G.keys[i])) == want then via = i break end
end
if not via then print("нет живого состояния с такой конфигурацией") return end
-- путь старт → via (по parent, это BFS-дерево)
local path, x = {}, via
while x ~= 1 do table.insert(path, 1, x); x = G.parent[x] end
table.insert(path, 1, 1)
-- BFS via → победа
local prev, q, h = { [via] = 0 }, { via }, 1
local winAt
while h <= #q do
  local u = q[h]; h = h + 1
  if G.flag[u] == 1 then winAt = u break end
  for e = G.eStart.p[u - 1], G.eStart.p[u] - 1 do
    local v = G.edges.p[e]
    if prev[v] == nil then prev[v] = u; q[#q + 1] = v end
  end
end
local tail, y = {}, winAt
while y ~= via do table.insert(tail, 1, y); y = prev[y] end
for _, v in ipairs(tail) do path[#path + 1] = v end
print(string.format("ходов всего %d (до конфигурации %d)", #path - 1, G.depth[via]))
if arg[3] == "frames" then
  local SYM = { source = "S", fixture = "F", stub = "T", pipe = "=", fitting = "b", porcelain = "P" }
  local function show(s)
    local rows = {}
    for yy = 1, lvl.H do rows[yy] = {} for xx = 1, lvl.W do local c = lvl.cell[(yy-1)*lvl.W+xx]; rows[yy][xx] = c == 1 and "#" or (c == 2 and "~" or ".") end end
    for qq, pp in ipairs(lvl.pieces) do if s.pos[qq] ~= 0 then local xx, yy = R.xy(lvl, s.pos[qq]); local ch = SYM[pp.kind]; if pp.movable then ch = s.fixed[qq] and ch:upper() or ch:lower() end; rows[yy][xx] = ch end end
    for k, c in ipairs(s.body) do local xx, yy = R.xy(lvl, c); rows[yy][xx] = (k == #s.body) and "H" or ((k == 1) and "f" or "o") end
    local out = {}
    for yy = 1, lvl.H do out[#out + 1] = table.concat(rows[yy]) end
    return out
  end
  local frames = {}
  for i, id in ipairs(path) do
    local st = R.decode(lvl, G.keys[id])
    local mv = i > 1 and (prev[id] and prev[id] ~= 0 and nil) or nil
    local f = show(st); table.insert(f, 1, string.format("%-" .. (lvl.W) .. "s", (i - 1) .. (good[id] == 1 and "" or "!")))
    frames[#frames + 1] = f
  end
  local per = math.max(1, math.floor(120 / (lvl.W + 2)))
  for k = 1, #frames, per do
    for line = 1, #frames[k] do
      local parts = {}
      for j = k, math.min(k + per - 1, #frames) do parts[#parts + 1] = string.format("%-" .. (lvl.W + 2) .. "s", frames[j][line] or "") end
      print(table.concat(parts, ""))
    end
    print()
  end
end
