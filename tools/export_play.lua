-- tools/export_play.lua 1 2 3 — проигрывает оптимальные решения ядром правил и пишет кадры
-- состояний (с трассой падений и толчков) в build/video/playNN.json. Сами ходы наружу не печатает.
package.path = "./?.lua;" .. package.path
local R = require("core.rules")
local SV = require("solver.solve")
local DIRS = { up = 1, right = 2, down = 3, left = 4 }

local function enc(v)
  local t = type(v)
  if t == "table" then
    local o = {}
    if #v > 0 or next(v) == nil then
      for i = 1, #v do o[i] = enc(v[i]) end
      return "[" .. table.concat(o, ",") .. "]"
    end
    for k, x in pairs(v) do o[#o + 1] = '"' .. tostring(k) .. '":' .. enc(x) end
    return "{" .. table.concat(o, ",") .. "}"
  elseif t == "string" then return '"' .. v .. '"' end
  return tostring(v)
end

os.execute("mkdir -p build/video")
for _, a in ipairs(arg) do
  local id = tonumber(a)
  local def = dofile(string.format("levels/%02d.lua", id))
  local lvl = R.compile(def)
  local res = SV.analyze(def, { cap = 300000 })
  assert(res.solution, "нет решения")
  local st, frames = R.newState(lvl), {}
  local function snap(s, kind, which, k)
    local cells, pos = {}, {}
    for i, c in ipairs(s.body) do local x, y = R.xy(lvl, c); cells[i] = { x, y } end
    for q = 1, #s.pos do
      if s.pos[q] and s.pos[q] > 0 then local x, y = R.xy(lvl, s.pos[q]); pos[q] = { x, y } else pos[q] = false end
    end
    frames[#frames + 1] = { kind = kind, which = which, move = k, cells = cells, pos = pos, dead = s.dead and true or false, win = R.isWin(lvl, s) and true or false }
  end
  local w1 = R.moveName(res.solution[1]):match("^(%a+):%a+$")
  assert(w1, "неожиданный формат имени хода")
  snap(st, "start", w1, 0)
  for k, mv in ipairs(res.solution) do
    local which, dn = R.moveName(mv):match("^(%a+):(%a+)$")
    local trace = {}
    local ns = R.move(lvl, st, which, DIRS[dn], trace)
    assert(ns, "ход отклонён: " .. k)
    for _, f in ipairs(trace) do snap(f.state, f.kind, which, k) end
    st = ns
  end
  local f = assert(io.open(string.format("build/video/play%02d.json", id), "w"))
  f:write(enc({ id = id, moves = #res.solution, frames = frames }))
  f:close()
  print(string.format("квартира %d: ходов %d, кадров состояния %d, победа в конце: %s", id, #res.solution, #frames, tostring(R.isWin(lvl, st))))
end
