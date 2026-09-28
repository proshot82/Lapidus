-- build/l3c/line.lua файл.lua — одна строка метрик для LOG.md (без решений):
-- ходы | состояния | скрытых при своём правиле / при d (заклинившее мыло видно) / при e (полка без подставки) |
-- умная обезьяна | глубина у пути | наобум | кратчайших/ширина | прогулки | вынужденных подряд | выигрышных | абляции
package.path = "./?.lua;" .. package.path
local f = arg[1]
local function run(extra)
  local p = io.popen("luajit build/l3c/ev.lua " .. f .. " " .. extra .. " 2>&1")
  local s = p:read("*a"); p:close(); return s
end
local full = run("")
if full:match("НЕРЕШАЕМ") or full:match("ОШИБКИ") then print(f .. ": " .. full:gsub("\n", " ")) return end
local d, e = run("rule=d quick"), run("rule=e quick")
local function g(s, pat) return s:match(pat) or "?" end
print(string.format("ходов %s | состояний %s | скрытых %s%% (d %s%%, e %s%%) | обезьяна %s%% | глубина %s (d %s) | наобум %s%% | кратчайших %s, ширина %s | прогулки %s | вынужд. подряд %s | выигрышных %s | %s",
  g(full, "ходов (%d+)"), g(full, "состояний (%d+)"), g(full, "СКРЫТЫХ (%d+)"), g(d, "СКРЫТЫХ (%d+)"), g(e, "СКРЫТЫХ (%d+)"),
  g(full, "ОБЕЗЬЯНА ([%d%.]+)"), g(full, "ГЛУБИНА (%d+)"), g(d, "ГЛУБИНА (%d+)"), g(full, "наобум ([%d%.]+)"),
  g(full, "кратчайших (%d+)"), g(full, "ширина (%d+)"), g(full, "отрезки без событий: ([%d,]+)"),
  g(full, "вынужденных подряд max (%d+)"), g(full, "выигрышных (%d+)"), g(full, "абляции: ([^\n]+)")))
