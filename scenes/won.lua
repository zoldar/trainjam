local lg = love.graphics
local scenes = require("lib.scenes")
local camera = require("lib.camera")

local won = {}

function won:init()
  BUS:subscribeOnce("keypressed_use", function()
    scenes.switch("game", "level2")
  end)

  self.camera = camera:new()
end

function won:draw()
  self.camera:attach()

  lg.printf("YOU WON!\nPRESS SPACE TO RESTART", 0, GAME_HEIGHT / 2, GAME_WIDTH, "center")

  self.camera:detach()
end

return won
