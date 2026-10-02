-- build/l2v2/drops.lua — k4: куда ведут падения с гребня (по классам итогов). Без ходов.
package.path = "./?.lua;" .. package.path
arg = { "build/l2e/k4.lua" }
local real = print; print = function() end
local P = dofile("build/l2v2/probe.lua")
print = real
local R = require("core.rules"); local def = dofile(arg[1]); local lvl = R.compile(def)
local sts, succ, live, dead = P.sts, P.succ, P.live, P.dead
local W = lvl.W
local function miny(st) local m = 99; for _, c in ipairs(st.body) do local y = math.floor((c - 1) / W) + 1; if y < m then m = y end end; return m end
local function minx(st) local m = 99; for _, c in ipairs(st.body) do local x = (c - 1) % W + 1; if x < m then m = x end end; return m end
local function anch(st) local p = R.occupancy(st); local t = {}
  for _, w in ipairs({ "head", "heel" }) do local q = R.endScrew(lvl, st, p, w); if q then t[#t + 1] = (lvl.pieces[q].tag or "?") end end
  return table.concat(t, ",") end
local c = {}
for i = 1, #sts do if live[i] and miny(sts[i]) <= 2 then for _, e in ipairs(succ[i]) do if e.fall then
  local s = sts[e.j]
  local k = (dead[e.j] and "карман" or "живое") .. " / " .. (minx(s) >= 8 and "дымоход" or "колодец") .. " / якорь [" .. anch(s) .. "]"
  c[k] = (c[k] or 0) + 1 end end end end
for k, v in pairs(c) do print(v, k) end
