-- build/l3d/cls.lua файл [карман] — классы скрытых тупиков по положению мыла (без ходов): число состояний,
-- входы живое→скрытое (всего и с кратчайшего пути, по шагам) — для поиска ошибок плана во второй половине.
package.path = "./?.lua;" .. package.path
local V = require("tools.vislib")
V.POCKET = tonumber(arg[2] or 4)
local L = dofile("build/l3v/lib.lua")
local ctx = L.load(arg[1])
local G = ctx.G
local path = L.path(ctx)
local onPath = {}
for k, id in ipairs(path) do onPath[id] = k - 1 end
local cnt, entries, pathEntries, total = {}, {}, {}, 0
for i = 1, G.n do
  if L.status(ctx, i) == "hid" then
    total = total + 1
    local k = L.cfg(ctx, ctx.sts[i]); cnt[k] = (cnt[k] or 0) + 1
  end
end
for i = 1, G.n do
  if L.status(ctx, i) == "live" then
    for _, j in ipairs(L.edges(ctx, i)) do
      if L.status(ctx, j) == "hid" then
        local k = L.cfg(ctx, ctx.sts[j])
        entries[k] = (entries[k] or 0) + 1
        if onPath[i] then pathEntries[k] = (pathEntries[k] or "") .. " " .. onPath[i] end
      end
    end
  end
end
print(string.format("скрытых %d (карман %d), путь %d ходов", total, V.POCKET, #path - 1))
local keys = {}
for k in pairs(cnt) do keys[#keys + 1] = k end
table.sort(keys, function(a, b) return cnt[a] > cnt[b] end)
for _, k in ipairs(keys) do
  print(string.format("%6d  %-28s входов %4d  с пути на шагах:%s", cnt[k], k, entries[k] or 0, pathEntries[k] or " —"))
end
L.free(ctx)
