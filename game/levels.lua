-- Загрузка уровней levels/NN.lua и решений puzzles/solutions.json.
local J = require("util.json")
local L = {}
function L.load()
  local list = {}
  -- служебно: LAP_LEVELS="91,92" — загрузить только эти файлы (витрины арта build/showcase); в игре не используется
  local only = os.getenv("LAP_LEVELS")
  if only then
    for n in only:gmatch("%d+") do list[#list + 1] = love.filesystem.load(string.format("levels/%02d.lua", tonumber(n)))() end
    return list
  end
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
