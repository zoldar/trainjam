local lg = love.graphics
local assets = require("assets")
local scenes = require("lib.scenes")
local camera = require("lib.camera")

local intro = {}

function intro:init()
  BUS:subscribeOnce("mouseclicked_primary", function()
    scenes.switch("game")
  end)

  BUS:subscribeOnce("keypressed_use", function()
    scenes.switch("game")
  end)

  self.camera = camera:new()
end

function intro:draw()
  self.camera:attach()

  lg.printf(
    "TRAIN JAM",
    assets.fonts.logo,
    0,
    10,
    GAME_WIDTH,
    "center"
  )

  lg.printf(
    "PRESS SPACE TO CONTINUE",
    assets.fonts.standard,
    0,
    GAME_HEIGHT - assets.fonts.standard:getHeight() - 20,
    GAME_WIDTH,
    "center"
  )

  self.camera:detach()
end

return intro
