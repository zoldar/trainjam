local assets = require("assets")
local keys = require("lib.keys")
local v = require("lib.vector")
local camera = require("lib.camera")
local scenes = require("lib.scenes")
local slick = require("vendor.slick.slick")
local lg = love.graphics

local game = { debug = false }

function game:init()
  game.camera = camera:new()
  game.world = slick.newWorld(GAME_WIDTH, GAME_HEIGHT)

  game.debugListener = BUS:subscribe("keypressed_debug", function()
    game.debug = not game.debug
  end)
end

function game:update(dt) end

function game:draw()
  game.camera:attach()

  lg.print("TBD")

  if game.debug then
    slick.drawWorld(game.world)
  end

  game.camera:detach()
end

function game:close()
  BUS:unsubscribe(game.debugListener)
end

return game
