-- starts.lua файл.lua [len] [макс] — перебор стартов Лапидуса (все змейки длины len, обе ориентации) для готовой раскладки.
-- Печатает лучшие по воротам (скрытые, прогулка, обезьяна). Только метрики.
package.path = "./?.lua;" .. package.path
local Q = dofile("build/l6c/b_wall_forever/quick.lua")
local base = dofile(arg[1])
local L = tonumber(arg[2] or 3)
local maxOut = tonumber(arg[3] or 12)
local G = base.grid
local H, W = #G, #G[1]
local function open(x, y) return y >= 1 and y <= H and x >= 1 and x <= W and G[y]:sub(x, x) == "." end
local occ = {}
local objs = {}
for _, o in ipairs(base.objects) do if o.kind ~= "lapidus" then objs[#objs + 1] = o; occ[o.at[1] .. "," .. o.at[2]] = true end end
local snakes = {}
local function ext(path, used)
  if #path == L then snakes[#snakes + 1] = { unpack(path) } return end
  local x, y = path[#path][1], path[#path][2]
  for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
    local nx, ny = x + d[1], y + d[2]
    local k = nx .. "," .. ny
    if open(nx, ny) and not occ[k] and not used[k] then
      used[k] = true; path[#path + 1] = { nx, ny }; ext(path, used); path[#path] = nil; used[k] = nil
    end
  end
end
for y = 1, H do for x = 1, W do if open(x, y) and not occ[x .. "," .. y] then ext({ { x, y } }, { [x .. "," .. y] = true }) end end end
local res = {}
for i, s in ipairs(snakes) do
  local o = {}
  for k, v in ipairs(objs) do o[k] = v end
  o[#o + 1] = { kind = "lapidus", cells = s, head = L }
  local def = {}
  for k, v in pairs(base) do def[k] = v end
  def.objects = o
  local ok, m = pcall(Q.metrics, def, 400000)
  if ok and m and not m.err and not m.unsolv and m.nwin == 1 then
    local sc = math.min(m.hidpct, 50) / 10 - math.log10(math.max(m.smart, 0.001)) * 2 - math.max(0, m.walk - 6) * 1.5 + math.min(m.deep, 10) / 5 - math.max(0, m.width - 3)
    res[#res + 1] = { sc = sc, m = m, s = s }
  end
end
table.sort(res, function(a, b) return a.sc > b.sc end)
print(string.format("стартов %d, годных %d", #snakes, #res))
for i = 1, math.min(maxOut, #res) do
  local r = res[i]
  local cs = {}
  for _, c in ipairs(r.s) do cs[#cs + 1] = "{" .. c[1] .. "," .. c[2] .. "}" end
  print(string.format("%5.1f %s  %s", r.sc, table.concat(cs, ""), Q.line(r.m)))
end
