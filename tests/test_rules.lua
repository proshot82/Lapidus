-- tests/test_rules.lua — юнит-тесты краевых случаев ядра: luajit tests/test_rules.lua
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local S = require("core.search")

local passed, failed = 0, 0
local function check(name, cond, info)
  if cond then
    passed = passed + 1
  else
    failed = failed + 1
    print("FAIL: " .. name .. (info ~= nil and ("  [" .. tostring(info) .. "]") or ""))
  end
end
local function L(grid, objects, len, pressure)
  return R.compile({ grid = grid, objects = objects, length = len or { 2, 5 }, pressure = pressure or 0 })
end
local function I(lvl, x, y) return (y - 1) * lvl.W + x end
local function bodyStr(lvl, st)
  local t = {}
  for i = 1, #st.body do
    local x, y = R.xy(lvl, st.body[i])
    t[#t + 1] = x .. "," .. y
  end
  return table.concat(t, " ")
end
local function mv(lvl, st, which, dir) return R.move(lvl, st, which, R.DIRINDEX[dir]) end
local function lap(cells, head) return { kind = "lapidus", cells = cells, head = head } end

do -- 1. растяжение, скольжение, сжатие, стена
  local lvl = L({ "#######", "#.....#", "#.....#", "#######" }, { lap({ { 2, 3 }, { 3, 3 } }, 2) }, { 2, 3 })
  local s = R.newState(lvl)
  local a = mv(lvl, s, "head", "right")
  check("stretch", a and bodyStr(lvl, a) == "2,3 3,3 4,3", a and bodyStr(lvl, a))
  local b = mv(lvl, a, "head", "right")
  check("slide at Lmax", b and bodyStr(lvl, b) == "3,3 4,3 5,3", b and bodyStr(lvl, b))
  local c = mv(lvl, b, "head", "left")
  check("compress", c and bodyStr(lvl, c) == "3,3 4,3", c and bodyStr(lvl, c))
  local d, why = mv(lvl, c, "head", "left")
  check("compress at Lmin blocked", d == nil and why == "short", why)
  local e = mv(lvl, c, "heel", "up")
  check("heel stretches up", e and bodyStr(lvl, e) == "3,2 3,3 4,3", e and bodyStr(lvl, e))
  local f, why2 = mv(lvl, c, "heel", "down")
  check("wall blocks", f == nil and why2 == "wall", why2)
end

do -- 2. мыло: голова не толкает фаянс, ноги толкают; цепочка упирается в стену
  local g = { "########", "#......#", "########" }
  local lvl = L(g, { { kind = "porcelain", at = { 4, 2 } }, lap({ { 2, 2 }, { 3, 2 } }, 2) })
  local a, why = mv(lvl, R.newState(lvl), "head", "right")
  check("head cannot push porcelain", a == nil and why == "soap", why)
  local lvl2 = L(g, { { kind = "porcelain", at = { 4, 2 } }, lap({ { 5, 2 }, { 6, 2 } }, 2) })
  local b = mv(lvl2, R.newState(lvl2), "heel", "left")
  check("heel pushes porcelain", b and b.pos[1] == I(lvl2, 3, 2) and b.body[1] == I(lvl2, 4, 2))
  local lvl3 = L(g, { { kind = "porcelain", at = { 2, 2 } }, lap({ { 3, 2 }, { 4, 2 } }, 2) })
  local c, why3 = mv(lvl3, R.newState(lvl3), "heel", "left")
  check("push into wall blocked", c == nil and why3 == "blocked", why3)
end

do -- 3. слипание подвижных по резьбе и толчок сборки целиком
  local lvl = L({ "##########", "#........#", "##########" },
    { { kind = "fitting", at = { 4, 2 }, ports = { right = "N" } },
      { kind = "fitting", at = { 6, 2 }, ports = { left = "V" } },
      lap({ { 2, 2 }, { 3, 2 } }, 2) })
  local s = R.newState(lvl)
  check("no merge at distance", s.asm[1] ~= s.asm[2])
  local a = mv(lvl, s, "head", "right")
  check("merge after push", a and a.asm[1] == a.asm[2] and not a.fixed[1])
  local b = mv(lvl, a, "head", "right")
  check("assembly pushed as one", b and b.pos[1] == I(lvl, 6, 2) and b.pos[2] == I(lvl, 7, 2))
end

do -- 4. конец Лапидуса к подвижной детали не прикручивается
  local lvl = L({ "#######", "#.....#", "#######" },
    { { kind = "fitting", at = { 4, 2 }, ports = { left = "N", right = "N" } }, lap({ { 2, 2 }, { 3, 2 } }, 2) })
  local s = R.newState(lvl)
  check("no screw into movable", R.endScrew(lvl, s, R.occupancy(s), "head") == nil and not s.fixed[1])
end

do -- 5. деталь прикручивается к закреплённому на лету и закрепляется
  local lvl = L({ "#####", "#...#", "#...#", "#...#", "#####" },
    { { kind = "stub", at = { 2, 3 }, ports = { right = "N" } },
      { kind = "fitting", at = { 3, 2 }, ports = { left = "V" } },
      lap({ { 4, 4 }, { 4, 3 } }, 2) })
  local s = R.newState(lvl)
  check("mid-fall screw fixes the piece", s.pos[2] == I(lvl, 3, 3) and s.fixed[2], s.pos[2])
end

do -- 6. висит на резьбе; «натянут»; ход прикрученным концом откручивает
  local grid = { "######", "#....#", "#....#", "#....#", "#....#", "######" }
  local objs = { { kind = "stub", at = { 3, 2 }, ports = { down = "N" } }, lap({ { 3, 4 }, { 3, 3 } }, 2) }
  local lvl = L(grid, objs, { 2, 3 })
  local s = R.newState(lvl)
  check("hangs screwed", bodyStr(lvl, s) == "3,4 3,3" and R.endScrew(lvl, s, R.occupancy(s), "head") == 1, bodyStr(lvl, s))
  local a = mv(lvl, s, "heel", "down")
  check("stretch while hanging", a and bodyStr(lvl, a) == "3,5 3,4 3,3", a and bodyStr(lvl, a))
  local lvl2 = L(grid, objs, { 2, 2 })
  local b, why = mv(lvl2, R.newState(lvl2), "heel", "down")
  check("taut blocks slide", b == nil and why == "taut", why)
  local c = mv(lvl, s, "head", "left")
  check("unscrew and fall rigidly", c and bodyStr(lvl, c) == "3,5 3,4 2,4", c and bodyStr(lvl, c))
end

do -- 7. слив: деталь смывает, Лапидуса — поражение
  local g = { "#######", "#.....#", "#.....#", "###~###" }
  local lvl = L(g, { { kind = "porcelain", at = { 4, 2 } }, lap({ { 5, 3 }, { 6, 3 } }, 2) })
  check("piece washed away", R.newState(lvl).pos[1] == 0)
  local lvl2 = L(g, { lap({ { 5, 3 }, { 4, 3 } }, 2) })
  local a = mv(lvl2, R.newState(lvl2), "head", "down")
  check("lapidus washed = dead", a and a.dead, a and bodyStr(lvl2, a))
  local b, why = R.move(lvl2, a, "head", R.UP)
  check("no moves when dead", b == nil and why == "dead", why)
end

do -- 8. вода, протечка из свободного конца, победа, BFS
  local lvl = R.compile({ grid = { "########", "#......#", "########" }, length = { 2, 4 }, pressure = 0,
    objects = { { kind = "source", at = { 2, 2 }, ports = { right = "N" } },
                { kind = "fixture", what = "bath", at = { 7, 2 }, ports = { left = "V" } },
                lap({ { 5, 2 }, { 4, 2 } }, 2) } })
  local errs = R.validate(lvl)
  check("validate ok", #errs == 0, errs[1])
  local s = R.newState(lvl)
  check("not won at start", not R.isWin(lvl, s))
  local a = mv(lvl, s, "head", "left")
  local st = R.status(lvl, a)
  check("head screwed, heel leaks", #st.leaks == 1 and st.leaks[1].lapidus == "heel", #st.leaks)
  local res, path = S.run(lvl, s, 10000)
  check("bfs finds 2-move solution", res == "found" and #path == 2, res)
  local cur = s
  for _, m in ipairs(path or {}) do cur = R.move(lvl, cur, R.MOVES[m].which, R.MOVES[m].dir) end
  check("solution wins", cur and R.isWin(lvl, cur))
end

do -- 9. Лапидус обязан быть на маршруте
  local lvl = L({ "########", "#......#", "#......#", "########" },
    { { kind = "source", at = { 2, 2 }, ports = { right = "N" } },
      { kind = "pipe", at = { 3, 2 }, ports = { left = "V", right = "N" } },
      { kind = "fixture", at = { 4, 2 }, ports = { left = "V" } },
      lap({ { 6, 3 }, { 7, 3 } }, 2) })
  local st = R.status(lvl, R.newState(lvl))
  check("fixture wet without lapidus", st.wetFixtures == 1 and #st.leaks == 0)
  check("no win when lapidus is not on the route", not st.win)
end

do -- 10. струя вверх — столб-лифт
  local lvl = L({ "#####", "#...#", "#...#", "#...#", "#...#", "#...#", "#####" },
    { { kind = "source", at = { 3, 6 }, ports = { up = "N" } },
      { kind = "porcelain", at = { 3, 5 } },
      lap({ { 2, 6 }, { 2, 5 } }, 2) }, { 2, 5 }, 2)
  check("pillar lifts to top+1", R.newState(lvl).pos[2] == I(lvl, 3, 3))
end

do -- 11. резьба сильнее струи: фонтан глушится только сбоку
  local grid = { "######", "#....#", "#....#", "#....#", "#....#", "#....#", "######" }
  local lvl = L(grid,
    { { kind = "source", at = { 4, 6 }, ports = { up = "N" } },
      { kind = "porcelain", at = { 3, 6 } },
      { kind = "fitting", at = { 3, 5 }, ports = { down = "V" } },
      lap({ { 2, 6 }, { 2, 5 } }, 2) }, { 2, 5 }, 2)
  local s = R.newState(lvl)
  check("cap rests before push", s.pos[3] == I(lvl, 3, 5) and not s.fixed[3], s.pos[3])
  local a = mv(lvl, s, "head", "right")
  local st = a and R.status(lvl, a)
  check("cap screws into the fountain from the side",
    a and a.fixed[3] and a.pos[3] == I(lvl, 4, 5) and #st.leaks == 0, a and a.pos[3])
  local lvl2 = L(grid,
    { { kind = "source", at = { 4, 6 }, ports = { up = "N" } },
      { kind = "fitting", at = { 4, 2 }, ports = { down = "V" } },
      lap({ { 2, 6 }, { 2, 5 } }, 2) }, { 2, 5 }, 2)
  local s2 = R.newState(lvl2)
  check("cap dropped from above hovers on the fountain", s2.pos[2] == I(lvl2, 4, 3) and not s2.fixed[2], s2.pos[2])
end

do -- 12. горизонтальная струя выталкивает груз за свою длину
  local lvl = L({ "#########", "#.......#", "#.......#", "#########" },
    { { kind = "source", at = { 2, 3 }, ports = { right = "N" } },
      { kind = "porcelain", at = { 3, 3 } },
      lap({ { 8, 3 }, { 8, 2 } }, 2) }, { 2, 5 }, 3)
  check("horizontal jet pushes out of range", R.newState(lvl).pos[2] == I(lvl, 6, 3))
end

do -- 13. встречные струи гасят друг друга
  local lvl = L({ "#########", "#.......#", "#.......#", "#########" },
    { { kind = "source", at = { 2, 3 }, ports = { right = "N" } },
      { kind = "source", at = { 6, 3 }, ports = { left = "N" } },
      { kind = "porcelain", at = { 4, 3 } },
      lap({ { 8, 3 }, { 8, 2 } }, 2) }, { 2, 5 }, 3)
  check("opposing jets cancel", R.newState(lvl).pos[3] == I(lvl, 4, 3))
end

do -- 14. брандспойт: свободный конец мокрого Лапидуса бьёт струёй, его самого не сносит
  local lvl = L({ "##########", "#........#", "#........#", "##########" },
    { { kind = "source", at = { 2, 3 }, ports = { right = "N" } },
      { kind = "porcelain", at = { 5, 3 } },
      lap({ { 4, 3 }, { 3, 3 } }, 2) }, { 2, 5 }, 3)
  local s = R.newState(lvl)
  check("hose jet pushes porcelain", s.pos[2] == I(lvl, 8, 3), s.pos[2])
  check("anchored hose is not pushed", bodyStr(lvl, s) == "4,3 3,3", bodyStr(lvl, s))
end

do -- 15. детерминизм и сериализация
  local lvl = L({ "##########", "#........#", "#........#", "#........#", "##########" },
    { { kind = "source", at = { 2, 4 }, ports = { right = "N" } },
      { kind = "fitting", at = { 5, 4 }, ports = { left = "V", up = "N" } },
      { kind = "fitting", at = { 7, 2 }, ports = { down = "V" } },
      { kind = "porcelain", at = { 8, 4 } },
      lap({ { 3, 2 }, { 4, 2 } }, 2) }, { 2, 5 }, 2)
  local function run(seed)
    local s = R.newState(lvl)
    local keys = {}
    local x = seed
    for _ = 1, 400 do
      x = (x * 16807) % 2147483647
      local m = x % 8 + 1
      local ns = R.move(lvl, s, R.MOVES[m].which, R.MOVES[m].dir)
      if ns and not ns.dead then s = ns end
      keys[#keys + 1] = R.key(s)
    end
    return keys
  end
  local k1, k2 = run(42), run(42)
  local same, rt = true, true
  for i = 1, #k1 do
    if k1[i] ~= k2[i] then same = false end
    if R.key(R.decode(lvl, k1[i])) ~= k1[i] then rt = false end
  end
  check("deterministic replay", same)
  check("key/decode roundtrip", rt)
end

do -- 16. слипание на лету при падении
  local lvl = L({ "#####", "#...#", "#...#", "#...#", "#...#", "#####" },
    { { kind = "fitting", at = { 3, 5 }, ports = { up = "N" } },
      { kind = "fitting", at = { 3, 2 }, ports = { down = "V" } },
      lap({ { 2, 5 }, { 2, 4 } }, 2) })
  local s = R.newState(lvl)
  check("merge on landing", s.asm[1] == s.asm[2] and s.pos[2] == I(lvl, 3, 4), s.pos[2])
end

do -- 17. валидатор ловит дыру в рамке
  local lvl = L({ "#####", "#...#", "#....", "#####" }, { lap({ { 2, 3 }, { 3, 3 } }, 2) })
  check("validator catches open border", #R.validate(lvl) > 0)
end

do -- 18. в своё тело не ходят
  local lvl = L({ "######", "#....#", "#....#", "######" },
    { lap({ { 2, 3 }, { 2, 2 }, { 3, 2 }, { 3, 3 } }, 4) }, { 2, 5 })
  local a, why = mv(lvl, R.newState(lvl), "head", "left")
  check("cannot move into own body", a == nil and why == "self", why)
end

do -- 19. столб поднимает неприкрученного Лапидуса
  local lvl = L({ "#####", "#...#", "#...#", "#...#", "#...#", "#...#", "#...#", "#####" },
    { { kind = "source", at = { 3, 7 }, ports = { up = "N" } }, lap({ { 3, 6 }, { 3, 5 } }, 2) }, { 2, 5 }, 3)
  local s = R.newState(lvl)
  check("lapidus lifted by the pillar", bodyStr(lvl, s) == "3,3 3,2", bodyStr(lvl, s))
end

print(string.format("rules tests: %d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
