-- «Лапидус. Ни капли» — точка входа. Вся логика правил — в core/rules.lua.
local App = require("game.app")
function love.load(args) App.load(args) end
function love.update(dt) App.update(dt) end
function love.draw() App.draw() end
function love.resize(w, h) App.resize(w, h) end
function love.keypressed(k) App.key(k) end
function love.mousepressed(x, y, b, istouch) if not istouch then App.pointer("press", x, y) end end
function love.mousereleased(x, y, b, istouch) if not istouch then App.pointer("release", x, y) end end
function love.touchpressed(id, x, y) App.pointer("press", x, y) end
function love.touchreleased(id, x, y) App.pointer("release", x, y) end
function love.gamepadpressed(j, b) App.pad(b) end
