-- solver/run_all.lua — метрики уровней, коридоры §7 и абляции. Решения пишутся только
-- в puzzles/solutions.json и WALKTHROUGH_SPOILERS.md; отчёт reports/metrics.md — без решений.
-- Запуск: luajit solver/run_all.lua [номера уровней]   (по умолчанию 1..10)
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local J = require("util.json")

local ids = {}
if #arg > 0 then for _, a in ipairs(arg) do ids[#ids + 1] = tonumber(a) end else for i = 1, 10 do ids[#ids + 1] = i end end
local function readJSON(path)
  local f = io.open(path)
  if not f then return {} end
  local s = f:read("*a"); f:close()
  local ok, t = pcall(J.decode, s)
  return (ok and type(t) == "table") and t or {}
end
local function writeFile(path, s) local f = assert(io.open(path, "w")); f:write(s); f:close() end

local metrics = readJSON("reports/metrics.json")
local ST = require("solver.strict")
-- Принятые отклонения от стартовых цифр §7 (решение автора; ворота «наобум» и «ширина» не ослабляются).
local NOTES = {
  ["01"] = "ложных веток 0: на 211 состояниях областей ≥ 50 не бывает, ошибки здесь наказываются сразу (слив), а не тихим тупиком",
  ["02"] = "19 ходов при коридоре 22–38: перебор 384 вариантов не дал 22+ с сохранением ловушек; решает плейтест",
  ["03"] = "подставка (28.09, build/l3c/r2): 32 хода; одно мыло по замыслу уходит в слив — проигрыш задаёт def.visibleLoss (washOk); «ага» доказана абляциями «подставку не выбить», «мыло на мыло не ляжет», «мост запрещён», «подъёмник запрещён»; финальный подъём к трубам — 11 ходов без событий (структурно: ступенька в одно мыло при длине 5)",
  ["04"] = "раскладка пересобрана 28.09 (build/l4c, k35): 16 ходов при стартовом коридоре 30–50 — в предложенных 15–40; прогулка 10 → 5, скрытых тупиков 68 % (при самой широкой честной разметке 50 %); «ага» доказана абляциями «сборка заранее» и «по одной нельзя»",
  ["05"] = "минимальная раскладка 9×7: 15 ходов вместо коридора 35–60 — по решению Lao красота важнее длины; идея §6 доказана абляцией «ступенька запрещена»",
  ["06"] = "ядро «муфтой вперёд» 11×5 (второй поиск 28.09, build/l6c): 23 хода в коридоре; «ага» доказана абляциями «пара не держит муфту над сливом» и «ниппель не переходит муфту поверху»",
}
local sols = readJSON("puzzles/solutions.json")
for _, id in ipairs(ids) do
  local key = string.format("%02d", id)
  local path = "levels/" .. key .. ".lua"
  local fh = io.open(path)
  if fh then
    fh:close()
    local def = SV.loadDef(path)
    local T = def.target or {}
    local res = SV.analyze(def, { cap = 5000000 })
    local abl = SV.ablations(def, { cap = 5000000 })
    local fails = {}
    if #(res.errors or {}) > 0 then fails[#fails + 1] = "ошибки: " .. table.concat(res.errors, "; ")
    elseif res.capped then fails[#fails + 1] = "больше 5·10⁶ состояний"
    elseif not res.solvable then fails[#fails + 1] = "нерешаем"
    else
      if T.moves and (res.minMoves < T.moves[1] or res.minMoves > T.moves[2]) then fails[#fails + 1] = "ходы вне коридора" end
      if T.states and res.states > T.states then fails[#fails + 1] = "состояний больше коридора" end
      if T.dead and res.deadPct < T.dead then fails[#fails + 1] = "мало тупиков" end
      if T.fb and (res.falseBranches or 0) < T.fb then fails[#fails + 1] = "мало ложных веток" end
      if (res.unstable or 0) > 0 then fails[#fails + 1] = "неустойчивые состояния" end
    end
    for _, a in ipairs(abl) do if a.solvable ~= false then fails[#fails + 1] = "абляция «" .. a.name .. "» решаема" end end
    local sx = (res.solvable and (res.states or 0) <= 2000000) and ST.check(def, 2000000) or nil
    if res.solvable and res.winStates ~= 1 then fails[#fails + 1] = "выигрышных конфигураций " .. tostring(res.winStates) end
    if sx then
      if sx.monkey > 1.0 then fails[#fails + 1] = string.format("проходим наобум (%.2f %%)", sx.monkey) end
      if sx.maxWidth > 3 then fails[#fails + 1] = "широкий коридор решений (" .. sx.maxWidth .. ")" end
    elseif res.solvable then fails[#fails + 1] = "строгие проверки не посчитаны" end
    metrics[key] = {
      id = id, name = def.name, grid = #def.grid[1] .. "×" .. #def.grid, length = def.length, pressure = def.pressure or 0,
      states = res.states, minMoves = res.minMoves, deadPct = res.deadPct and math.floor(res.deadPct * 10 + 0.5) / 10,
      falseBranches = res.falseBranches, winStates = res.winStates, unstable = res.unstable, solvable = res.solvable,
      ablations = abl, target = T, corridor = (#fails == 0) and "ok" or table.concat(fails, "; "),
      monkey = sx and math.floor(sx.monkey * 100 + 0.5) / 100, shortest = sx and sx.shortest,
      shortestWidth = sx and sx.maxWidth, note = NOTES[key],
    }
    if res.solution then
      local names = {}
      for k, mv in ipairs(res.solution) do names[k] = R.moveName(mv) end
      sols[key] = { name = def.name, moves = names }
    end
    print(string.format("%s «%s»: %s | коридор: %s", key, def.name, SV.summary(res), metrics[key].corridor))
  end
end
writeFile("reports/metrics.json", J.encode(metrics, "  ") .. "\n")
writeFile("puzzles/solutions.json", J.encode(sols, "  ") .. "\n")

local keys = {}
for k in pairs(metrics) do keys[#keys + 1] = k end
table.sort(keys)
local md = { "# Метрики уровней «Лапидус. Ни капли»", "",
  "Считает солвер на том же ядре правил, что и игра (solver/run_all.lua). Решений в этом отчёте нет.", "",
  "Строгие ворота для всех уровней: наобум ≤ 1 % — точная вероятность, что случайный игрок (случайный допустимый ход, откат при «смыло», «Заново» после 5×нормы) пройдёт уровень за 1000 ходов; ширина ≤ 3 — сколько разных положений максимум лежит на кратчайших решениях на одном шаге.", "",
  "| № | Уровень | Поле | Длина | Напор | Состояний | Мин. ходов (коридор) | Тупиков | Ложных веток | Выигрышных конфигураций | Наобум (≤ 1 %) | Кратчайших (ширина ≤ 3) | Абляции | Итог |",
  "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |" }
for _, k in ipairs(keys) do
  local m = metrics[k]
  local T = m.target or {}
  local ab = {}
  for _, a in ipairs(m.ablations or {}) do ab[#ab + 1] = a.name .. ": " .. (a.solvable == false and "нерешаем ✓" or "решаем ✗") end
  md[#md + 1] = string.format("| %d | «%s» | %s | %d–%d | %d | %s (≤ %s) | %s (%s) | %s%% (≥ %s%%) | %s (≥ %s) | %s | %s %% | %s (%s) | %s | %s |",
    m.id, m.name, m.grid, m.length[1], m.length[2], m.pressure, tostring(m.states), tostring(T.states),
    tostring(m.minMoves), T.moves and (T.moves[1] .. "–" .. T.moves[2]) or "—", tostring(m.deadPct), tostring(T.dead),
    tostring(m.falseBranches), tostring(T.fb), tostring(m.winStates), tostring(m.monkey), tostring(m.shortest),
    tostring(m.shortestWidth), table.concat(ab, "; "),
    m.corridor == "ok" and "✅" or ((m.note and "⚠️ " or "❌ ") .. m.corridor))
end
local notes = {}
for _, k in ipairs(keys) do if metrics[k].note then notes[#notes + 1] = string.format("- Кв. %d: %s.", metrics[k].id, metrics[k].note) end end
if #notes > 0 then md[#md + 1] = ""; md[#md + 1] = "Принятые отклонения (⚠️):"; for _, n in ipairs(notes) do md[#md + 1] = n end end
writeFile("reports/metrics.md", table.concat(md, "\n") .. "\n")

local AR = { up = "↑", right = "→", down = "↓", left = "←" }
local sk = {}
for k in pairs(sols) do sk[#sk + 1] = k end
table.sort(sk)
local wt = { "# Прохождение «Лапидус. Ни капли» — СПОЙЛЕРЫ", "",
  "Оптимальные решения от солвера. Г — ход головой, Н — ход ногами, стрелка — направление. Смена конца ходом не считается.", "" }
for _, k in ipairs(sk) do
  local s = sols[k]
  wt[#wt + 1] = string.format("## Кв. %d · «%s» — %d ходов", tonumber(k), s.name, #s.moves)
  wt[#wt + 1] = ""
  local line = {}
  for i, name in ipairs(s.moves) do
    local w, d = name:match("^(%a+):(%a+)$")
    line[#line + 1] = string.format("%d. %s%s", i, (w == "head") and "Г" or "Н", AR[d])
    if #line == 10 or i == #s.moves then wt[#wt + 1] = table.concat(line, "  ") .. "  "; line = {} end
  end
  wt[#wt + 1] = ""
end
writeFile("WALKTHROUGH_SPOILERS.md", table.concat(wt, "\n"))
