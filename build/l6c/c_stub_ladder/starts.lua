-- starts.lua файл.lua [len] — локальная доводка: все устойчивые старты Лапидуса длины len (по умолчанию 3) в нижнем
-- ярусе; печатает ворота для лучших по «обезьяне» при прогулке ≤ 6 (для себя; решений не печатает).
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local GT = dofile("build/l6c/c_stub_ladder/gates.lua")
local SV = require("solver.solve")
local base = dofile(arg[1])
local len = tonumber(arg[2] or 3)
local rows = { tonumber(arg[3] or 6), tonumber(arg[4] or 7) }
local lvl = R.compile(base)
local W, H = lvl.W, lvl.H
local occ = {}
for _, o in ipairs(base.objects) do if o.kind ~= "lapidus" then occ[(o.at[2]-1)*W + o.at[1]] = true end end
local function free(x, y) if x < 1 or x > W or y < 1 or y > H then return false end local i = (y-1)*W+x return lvl.cell[i] == 0 and not occ[i] end
local paths = {}
local function ext(p)
  if #p == len then local cp = {} for i = 1, #p do cp[i] = { p[i][1], p[i][2] } end paths[#paths+1] = cp return end
  local x, y = p[#p][1], p[#p][2]
  for _, d in ipairs({ {1,0},{-1,0},{0,1},{0,-1} }) do
    local nx, ny = x + d[1], y + d[2]
    local ok = free(nx, ny) and ny >= rows[1] and ny <= rows[2]
    for _, q in ipairs(p) do if q[1] == nx and q[2] == ny then ok = false end end
    if ok then p[#p+1] = { nx, ny }; ext(p); p[#p] = nil end
  end
end
for y = rows[1], rows[2] do for x = 1, W do if free(x, y) then ext({ { x, y } }) end end end
local seen, res = {}, {}
for _, p in ipairs(paths) do
  for _, head in ipairs({ 1, len }) do
    local def = SV.deepcopy(base)
    for _, o in ipairs(def.objects) do if o.kind == "lapidus" then o.cells = p; o.head = head end end
    local l2 = R.compile(def)
    local st = R.newState(l2)
    local k = R.key(st)
    if not seen[k] and not st.dead then
      seen[k] = true
      local r = GT.eval(def, { noabl = true })
      if not r.unsolvable and r.walk then
        local cs = {}
        for _, c in ipairs(p) do cs[#cs+1] = c[1] .. "," .. c[2] end
        res[#res+1] = { r = r, s = table.concat(cs, " ") .. " h" .. head }
      end
    end
  end
end
table.sort(res, function(a, b) return a.r.smart < b.r.smart end)
for i = 1, math.min(tonumber(arg[5] or 15), #res) do
  local r = res[i].r
  print(string.format("%-28s %s | провалы: %s", res[i].s, r.line, table.concat(r.fails, ",")))
end
