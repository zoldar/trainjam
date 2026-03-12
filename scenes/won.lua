local lg = love.graphics
local assets = require("assets")
local scenes = require("lib.scenes")

local won = {}

function won:init(currentLevel)
  self.nextLevel = LEVELS[currentLevel]
end

function won:keypressed(key)
  if key == "use" then
    scenes.switch("game", { args = { self.nextLevel } })
  end
end

function won:mousereleased(_x, _y, button)
  if button == "use" then
    scenes.switch("game", { args = { self.nextLevel } })
  end
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

return won
