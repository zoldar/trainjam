local lg = love.graphics
local assets = require("assets")
local scenes = require("lib.scenes")

local won = {}

function won:init(currentLevel)
  self.actionListener = BUS:subscribeOnce("keypressed_use", function()
    scenes.switch("game", LEVELS[currentLevel])
  end)

  self.mouseListener = BUS:subscribeOnce("mouseclicked_primary", function()
    scenes.switch("game", LEVELS[currentLevel])
  end)
end

function won:draw()
  lg.setColor(0, 0, 0, 0.2)

  lg.rectangle("fill", 0, 0, GAME_WIDTH, GAME_HEIGHT)

  lg.setColor(1, 1, 1, 1)

  lg.printf(
    "GREAT JOB!\n\nCLICK TO CONTINUE",
    assets.fonts.standard,
    0,
    GAME_HEIGHT / 2,
    GAME_WIDTH,
    "center"
  )
end

function won:close()
  BUS:unsubscribe(self.mouseListener)
  BUS:unsubscribe(self.actionListener)
end

return won
