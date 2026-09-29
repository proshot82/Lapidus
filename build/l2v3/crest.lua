-- build/l2v3/crest.lua — k6: срывы с гребня (куда приводят), живые состояния гребня и лаза с выбором. Без ходов.
package.path = "./?.lua;" .. package.path
arg = { arg[1] or "build/l2e/k6.lua" }
local real = print; print = function() end
local P = dofile("build/l2v3/probe.lua"); print = real
local R = require("core.rules"); local lvl = R.compile(dofile(arg[1]))
local sts, succ, live, dead = P.sts, P.succ, P.live, P.dead
local W = lvl.W
local function crest(st) for _, c in ipairs(st.body) do local x, y = (c - 1) % W + 1, math.floor((c - 1) / W) + 1; if x < 6 or y > 2 then return false end end; return true end
local function tag(st) if st.dead then return "смыт" end local piece = R.occupancy(st); local t = {}
  for _, w in ipairs({ "head", "heel" }) do local q = R.endScrew(lvl, st, piece, w); if q then t[#t + 1] = (lvl.pieces[q].tag or lvl.pieces[q].kind) .. ":" .. w end end
  return #t > 0 and table.concat(t, ",") or "ни на чём" end
local nc, out = 0, {}
for i = 1, #sts do if crest(sts[i]) then nc = nc + 1
  for _, e in ipairs(succ[i]) do if e.fall and not crest(sts[e.j]) then
    local k = (live[e.j] and "живое" or "скрытое") .. " — " .. tag(sts[e.j]); out[k] = (out[k] or 0) + 1 end end end end
print("состояний на гребне: " .. nc)
for k, v in pairs(out) do print(string.format("  срывов с гребня: %d → %s", v, k)) end
-- все падения свободного тела (ни на чём не висит до хода) из живых: по ступени (колодец / шахта) и исходу
local function side(st) local mx = 0; for _, c in ipairs(st.body) do local x = (c - 1) % W + 1; if x > mx then mx = x end end; return mx >= 6 and "колодец" or "шахта/лаз" end
local o2 = {}
for i = 1, #sts do if live[i] and tag(sts[i]) == "ни на чём" then
  for _, e in ipairs(succ[i]) do if e.fall then
    local k = side(sts[e.j]) .. ": " .. (live[e.j] and "живое" or "скрытое") .. " — " .. tag(sts[e.j]); o2[k] = (o2[k] or 0) + 1 end end end end
local ks = {}; for k in pairs(o2) do ks[#ks + 1] = k end; table.sort(ks)
print("падения свободного тела из живых:"); for _, k in ipairs(ks) do print(string.format("  %3d  %s", o2[k], k)) end
