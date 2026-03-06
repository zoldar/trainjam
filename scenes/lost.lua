local lg = love.graphics
local assets = require("assets")
local scenes = require("lib.scenes")

local lost = {}

function lost:init(reason, currentLevel)
  self.actionListener = BUS:subscribeOnce("keypressed_use", function()
    scenes.switch("game", currentLevel)
  end)

  self.mouseListener = BUS:subscribeOnce("mouseclicked_primary", function()
    scenes.switch("game", currentLevel)
  end)

  if reason == "crashed" then
    self.message = "YOU CRASHED"
  elseif reason == "timeout" then
    self.message = "YOU RAN OUT OF TIME"
  elseif reason == "freight_missing" then
    self.message = "YOU DID NOT COLLECT ALL FREIGHT"
  else
    self.message = "YOU LOST"
  end
end

function lost:draw()
  lg.setColor(0, 0, 0, 0.4)

  lg.rectangle("fill", 0, 0, GAME_WIDTH, GAME_HEIGHT)

  lg.setColor(1, 1, 1, 1)

  lg.printf(
    self.message .. "\n\nCLICK TO TRY AGAIN",
    assets.fonts.standard,
    0,
    GAME_HEIGHT / 2,
    GAME_WIDTH,
    "center"
  )
end

function lost:close()
  BUS:unsubscribe(self.mouseListener)
  BUS:unsubscribe(self.actionListener)
end

return lost
