-- build/l7v_f/wall.lua файл.lua — замуровать по одной каждую пустую клетку и заменить стеной каждую деталь.
package.path = "./?.lua;" .. package.path
local L = require("build.l7v_f.lib")
local SV = require("solver.solve")
local path = arg[1]
local base = dofile(path)
print("база: " .. L.fmt(L.metrics(base, { abl = true, strict = true })))
local occ = {}
for _, o in ipairs(base.objects) do
  if o.at then occ[o.at[1] .. "," .. o.at[2]] = o.tag or o.what or o.kind end
  if o.cells then for _, c in ipairs(o.cells) do occ[c[1] .. "," .. c[2]] = "lap" end end
end
for y = 1, #base.grid do
  for x = 1, #base.grid[y] do
    if base.grid[y]:sub(x, x) == "." then
      local d = dofile(path)
      local k = x .. "," .. y
      local what = occ[k]
      if what == "nip" or what == "elb" or what == "plug" then
        for i, o in ipairs(d.objects) do if o.tag == what then table.remove(d.objects, i) break end end
        d.ablations = {}
      elseif what then goto cont end
      d.grid[y] = d.grid[y]:sub(1, x - 1) .. "#" .. d.grid[y]:sub(x + 1)
      local r = L.metrics(d, { abl = (what == nil) })
      print(string.format("(%d,%d)%s: %s", x, y, what and (" деталь " .. what .. "→стена") or "", L.fmt(r)))
      io.stdout:flush()
    end
    ::cont::
  end
end
