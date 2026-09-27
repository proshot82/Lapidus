-- Прогресс и настройки: JSON в папке сохранений LÖVE.
local J = require("util.json")
local S = { file = "save.json" }
function S.load()
  local data = { current = 1, solved = {}, best = {}, settings = { music = 0.7, sfx = 0.8 } }
  if love.filesystem.getInfo(S.file) then
    local ok, t = pcall(J.decode, love.filesystem.read(S.file))
    if ok and type(t) == "table" then for k, v in pairs(t) do data[k] = v end end
  end
  return data
end
function S.write(data) love.filesystem.write(S.file, J.encode(data)) end
return S
