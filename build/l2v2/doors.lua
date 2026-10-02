-- build/l2v2/doors.lua — k4: чем является каждая дверь с пути (каким концом ход, был ли этот конец прикручен). Без ходов.
package.path = "./?.lua;" .. package.path
arg = { arg[1] or "build/l2e/k4.lua" }
local real = print; print = function() end
local P = dofile("build/l2v2/probe.lua")
print = real
local R = require("core.rules")
local def = dofile(arg[1]); local lvl = R.compile(def)
local sts, succ, dead, path = P.sts, P.succ, P.dead, P.path
local function anch(st, w) local piece = R.occupancy(st); return R.endScrew(lvl, st, piece, w) ~= nil end
local cnt = {}
for k = 1, #path - 1 do local s = path[k]
  local pw
  for _, e in ipairs(succ[s]) do if e.j == path[k + 1] then pw = R.MOVES[e.m].which end end
  for _, e in ipairs(succ[s]) do if dead[e.j] then
    local w = R.MOVES[e.m].which
    local kind
    if anch(sts[s], w) then kind = "открутил прикрученный конец (отпустил крюк)"
    elseif not anch(sts[s], "head") and not anch(sts[s], "heel") then kind = "свободное тело: сорвался/сполз в колодец"
    else kind = "ход свободным концом при якоре (перевес/сползание)" end
    local k2 = string.format("шаг %2d: %s; тем же концом, что ход пути: %s", k - 1, kind, tostring(w == pw))
    print(k2)
    cnt[kind] = (cnt[kind] or 0) + 1
  end end
end
for k, v in pairs(cnt) do print(v, k) end
