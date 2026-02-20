local lg = love.graphics
local assets = require("assets")
local scenes = require("lib.scenes")
local camera = require("lib.camera")

local won = {}

function won:init(currentLevel)
  BUS:subscribeOnce("keypressed_use", function()
    scenes.switch("game", LEVELS[currentLevel])
  end)

  BUS:subscribeOnce("mouseclicked_primary", function()
    scenes.switch("game", LEVELS[currentLevel])
  end)

  self.camera = camera:new()
end

function won:draw()
  self.camera:attach()

  lg.setColor(0, 0, 0, 0.2)

  lg.rectangle("fill", 0, 0, GAME_WIDTH, GAME_HEIGHT)

  lg.setColor(1, 1, 1, 1)

  lg.printf(
    "YOU WON!\nPRESS SPACE TO CONTINUE",
    assets.fonts.standard,
    0,
    GAME_HEIGHT / 2,
    GAME_WIDTH,
    "center"
  )

  self.camera:detach()
end

return won
