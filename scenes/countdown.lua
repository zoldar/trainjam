local lg = love.graphics
local assets = require("assets")
local scenes = require("lib.scenes")
local camera = require("lib.camera")

local scene = {}

local function toDisplay(countdown)
  return tostring(math.ceil(countdown))
end

function scene:init()
  self.camera = camera:new()
  self.countdown = 3

  assets.sounds.blip1:play()
end

function scene:update(dt)
  local newCountdown = self.countdown - dt

  if math.ceil(newCountdown) < math.ceil(self.countdown) then
    if math.ceil(newCountdown) > 0 then
      assets.sounds.blip1:play()
    else
      assets.sounds.blip2:play()
    end
  end

  self.countdown = newCountdown

  if self.countdown <= 0 then
    scenes.pop()
  end
end

function scene:draw()
  self.camera:attach()

  lg.setColor(0, 0, 0, 0.2)

  lg.rectangle("fill", 0, 0, GAME_WIDTH, GAME_HEIGHT)

  lg.setColor(1, 1, 1, 1)

  lg.printf("STARTING IN " .. toDisplay(self.countdown), 0, GAME_HEIGHT / 2, GAME_WIDTH, "center")

  self.camera:detach()
end

return scene
