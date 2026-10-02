-- Звук (DESIGN §9): эффекты assets/sfx, музыка assets/music (синтез — tools/gen_audio.lua; любой трек заменяется
-- подменой файла). Музыка меняется с перекрёстным затуханием; горячая линия приглушает тему и включает «ожидание».
local Audio = { sfx = {}, cur = nil, vol = { music = 0.55, sfx = 0.8 }, on = true, log = os.getenv("LAP_AUDIO_LOG") ~= nil }

local function load(path, kind)
  if not love.filesystem.getInfo(path) then return nil end
  local ok, src = pcall(love.audio.newSource, path, kind)
  return ok and src or nil
end

function Audio.init(settings)
  if settings then
    Audio.vol.music = settings.music or Audio.vol.music
    Audio.vol.sfx = settings.sfx or Audio.vol.sfx
    if settings.sound == false then Audio.on = false end
  end
  Audio.music = {}
  for _, name in ipairs({ "dub", "bossa", "pressure", "hold" }) do
    local s = load("assets/music/" .. name .. ".ogg", "stream")
    if s then s:setLooping(true); s:setVolume(0); Audio.music[name] = { src = s, v = 0, goal = 0 } end
  end
  local jet = load("assets/sfx/jet.ogg", "static")
  if jet then jet:setLooping(true); jet:setVolume(0); Audio.jet = jet end
end

function Audio.play(name, vol, pitch)
  if Audio.log then print("SFX " .. name) end
  if not Audio.on then return end
  local s = Audio.sfx[name]
  if s == nil then s = load("assets/sfx/" .. name .. ".ogg", "static") or false; Audio.sfx[name] = s end
  if not s then return end
  local c = s:clone()
  c:setVolume((vol or 1) * Audio.vol.sfx)
  if pitch then c:setPitch(pitch) end
  c:play()
end

-- тема: "dub" (подвал), "bossa" (кв. 1–6), "pressure" (с напором), "hold" (горячая линия); duck — приглушить основную
function Audio.theme(name)
  Audio.cur = name
  for k, m in pairs(Audio.music or {}) do m.goal = (k == name) and 1 or 0 end
end
function Audio.hold(on)
  local m = Audio.music or {}
  if on then
    for k, x in pairs(m) do x.goal = (k == "hold") and 1 or ((k == Audio.cur) and 0.15 or 0) end
  else Audio.theme(Audio.cur) end
end

function Audio.setJet(level) Audio.jetGoal = level end

function Audio.toggle()
  Audio.on = not Audio.on
  return Audio.on
end

function Audio.update(dt)
  local master = Audio.on and 1 or 0
  for _, m in pairs(Audio.music or {}) do
    local target = m.goal * master
    if m.v < target then m.v = math.min(target, m.v + dt * 0.8) elseif m.v > target then m.v = math.max(target, m.v - dt * 1.2) end
    m.src:setVolume(m.v * Audio.vol.music)
    if m.v > 0 and not m.src:isPlaying() then m.src:play() elseif m.v == 0 and m.src:isPlaying() then m.src:pause() end
  end
  if Audio.jet then
    local g = (Audio.jetGoal or 0) * master
    local v = Audio.jet:getVolume()
    v = v + (g * Audio.vol.sfx * 0.5 - v) * math.min(1, dt * 4)
    Audio.jet:setVolume(v)
    if v > 0.01 and not Audio.jet:isPlaying() then Audio.jet:play() elseif v <= 0.01 and Audio.jet:isPlaying() then Audio.jet:pause() end
  end
end

return Audio
