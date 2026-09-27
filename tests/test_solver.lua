-- tests/test_solver.lua — проверка солвера и замер скорости: luajit tests/test_solver.lua
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local passed, failed = 0, 0
local function check(name, cond, info)
  if cond then passed = passed + 1 else failed = failed + 1; print("FAIL: " .. name .. "  [" .. tostring(info) .. "]") end
end
local function def8()
  return { id = 99, name = "t8", grid = { "########", "#......#", "########" }, length = { 2, 4 }, pressure = 0,
    objects = { { kind = "source", at = { 2, 2 }, ports = { right = "N" } },
                { kind = "fixture", at = { 7, 2 }, ports = { left = "V" } },
                { kind = "lapidus", cells = { { 5, 2 }, { 4, 2 } }, head = 2 } },
    ablations = { { name = "стояк смотрит в стену", mutate = function(d) d.objects[1].ports = { left = "N" } end } } }
end
local res = SV.analyze(def8())
check("solver: states > 0", (res.states or 0) > 0, res.states)
check("solver: min moves = 2", res.minMoves == 2, res.minMoves)
check("solver: deadPct in [0,100]", res.deadPct and res.deadPct >= 0 and res.deadPct <= 100, res.deadPct)
local lvl = R.compile(def8())
local s = R.newState(lvl)
for _, m in ipairs(res.solution or {}) do s = R.move(lvl, s, R.MOVES[m].which, R.MOVES[m].dir) end
check("solver: solution replays to a win", R.isWin(lvl, s))
local ab = SV.ablations(def8())
check("solver: ablation makes it unsolvable", ab[1] and ab[1].solvable == false, ab[1] and tostring(ab[1].solvable))
local ex = SV.analyze(SV.loadDef("levels/_format_example.lua"))
check("solver: format example validates", #ex.errors == 0, ex.errors[1])
print("format example: " .. SV.summary(ex))
local big = { name = "perf", length = { 2, 5 }, pressure = 0,
  grid = { "############", "#..........#", "#..........#", "#..........#", "#..........#", "#..........#", "#..........#", "############" },
  objects = { { kind = "source", at = { 2, 7 }, ports = { up = "N" } }, { kind = "fixture", at = { 11, 2 }, ports = { down = "V" } },
              { kind = "porcelain", at = { 5, 7 } }, { kind = "porcelain", at = { 8, 7 } },
              { kind = "fitting", at = { 6, 7 }, ports = { left = "V", right = "N" } },
              { kind = "lapidus", cells = { { 3, 7 }, { 4, 7 } }, head = 2 } } }
local rb = SV.analyze(big, { cap = 3000000 })
print("perf probe: " .. SV.summary(rb) .. string.format("  (%.1f us/state)", 1e6 * (rb.time or 0) / (rb.states or 1)))
print(string.format("solver tests: %d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
