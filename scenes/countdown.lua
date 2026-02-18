local lg = love.graphics
local scenes = require("lib.scenes")
local camera = require("lib.camera")

local scene = {}

local function toDisplay(countdown)
  return tostring(math.ceil(countdown))
end

function scene:init()
  self.camera = camera:new()
  self.countdown = 3
end

function scene:update(dt)
  self.countdown = self.countdown - dt

  if self.countdown <= 0 then
    scenes.pop()
  end
end

function scene:draw()
  self.camera:attach()

  lg.printf("STARTING IN " .. toDisplay(self.countdown), 0, GAME_HEIGHT / 2, GAME_WIDTH, "center")

  self.camera:detach()
end

return scene
