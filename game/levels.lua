-- Загрузка уровней levels/NN.lua и решений puzzles/solutions.json.
local J = require("util.json")
local L = {}
function L.load()
  local list = {}
  for i = 1, 10 do
    local path = string.format("levels/%02d.lua", i)
    if love.filesystem.getInfo(path) then list[#list + 1] = love.filesystem.load(path)() end
  end
  return list
end
function L.solutions()
  if love.filesystem.getInfo("puzzles/solutions.json") then
    local ok, t = pcall(J.decode, love.filesystem.read("puzzles/solutions.json"))
    if ok and type(t) == "table" then return t end
  end
  return {}
end
return L
