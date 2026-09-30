-- build/l3v2/tail.lua — варианты финала без смены ядра (зона шахты/верхнего коридора): метрики и прогулка.
-- Печатает только метрики; прогулку считает build/l6b/check.lua.
local function mk(name, rows, src, snk)
  local d = dofile("build/l3d/s8.lua")
  for y, r in pairs(rows) do d.grid[y] = r end
  for _, o in ipairs(d.objects) do
    if o.kind == "source" then o.at = src[1]; o.ports = src[2] end
    if o.kind == "fixture" then o.at = snk[1]; o.ports = snk[2] end
  end
  local f = "build/l3v2/tail_" .. name .. ".lua"
  local fh = io.open(f, "w")
  -- сериализация: только изменённые поля поверх s8
  fh:write("local d = dofile('build/l3d/s8.lua')\n")
  for y, r in pairs(rows) do fh:write(string.format("d.grid[%d] = %q\n", y, r)) end
  fh:write(string.format("for _, o in ipairs(d.objects) do if o.kind == 'source' then o.at = {%d,%d}; o.ports = {%s = 'V'} end if o.kind == 'fixture' then o.at = {%d,%d}; o.ports = {%s = 'N'} end end\nreturn d\n",
    src[1][1], src[1][2], next(src[2]), snk[1][1], snk[1][2], next(snk[2])))
  fh:close()
  print("== " .. name); io.stdout:flush()
  os.execute("luajit build/l6b/check.lua " .. f .. " | grep -E 'ходов|СКРЫТ|событий|ДВЕРИ|абляции|НЕРЕШ'")
end
-- mk("A_short", { [2] = "#####....##", [3] = "######.#.##", [4] = "##...#.#.##" }, { { 9, 4 }, { up = "V" } }, { { 6, 2 }, { right = "N" } })
-- mk("B_top", { [2] = "#####..####", [3] = "######..###", [4] = "##...#.####" }, { { 8, 3 }, { up = "V" } }, { { 6, 2 }, { right = "N" } })
-- mk("C_swap", { }, { { 6, 2 }, { right = "V" } }, { { 10, 4 }, { up = "N" } })
mk("D_low", { [2] = "###########", [3] = "#####.....#" }, { { 10, 4 }, { up = "V" } }, { { 6, 3 }, { right = "N" } })
mk("E_low_swap", { [2] = "###########", [3] = "#####.....#" }, { { 6, 3 }, { right = "V" } }, { { 10, 4 }, { up = "N" } })
