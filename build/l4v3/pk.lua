-- build/l4v3/pk.lua файл — что именно меняется при пороге кармана 3→4→5→6: какая деталь «запечатана» и в каком классе
package.path = "./?.lua;" .. package.path
local L = dofile("build/l4v3/lib.lua")
local file = arg[1]
local res = {}
for _, p in ipairs({ 3, 4, 5, 6 }) do
  local A = L.load(file, { pocket = p })
  local cls = L.classes(A)
  res[p] = { A = A, cls = cls }
end
for _, pr in ipairs({ { 3, 4 }, { 4, 5 }, { 5, 6 } }) do
  local a, b = res[pr[1]], res[pr[2]]
  local A = b.A
  local agg = {}
  for i = 1, A.G.n do if A.G.flag[i] ~= 2 and A.good[i] ~= 1 and not a.A.VL.newbie[i] and b.A.VL.newbie[i] then
    local st = A.sts[i]
    local k = L.classOf(A, b.cls, st)
    local who = {}
    for _, tag in ipairs({ "cpl", "nip", "elb" }) do local q = A.Q[tag]; if b.A.VL.sealedBy[q][i] then who[#who + 1] = tag end end
    local key = b.cls[k][1] .. " запечатан: " .. table.concat(who, "+")
    agg[key] = (agg[key] or 0) + 1
  end end
  print(string.format("порог %d→%d: становятся видимыми", pr[1], pr[2]))
  for k, v in pairs(agg) do print("   " .. k, v) end
end
-- для каждого класса: сколько клеток может занять запечатанная деталь (размер кармана) — по порогу 6
local A = res[6].A
