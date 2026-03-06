local push = require("vendor.push.push")
local assets = require("assets")
local Bus = require("lib.bus")
local scenes = require("lib.scenes")
local keys = require("lib.keys")
local inspect = require("vendor.inspect")

require("logic.constants")

INSPECT = function(...)
  print(inspect({ ... }))
  return ...
end

BUS = Bus:new()

love.graphics.setDefaultFilter("nearest", "nearest")
push:setupScreen(GAME_WIDTH, GAME_HEIGHT, 4 * GAME_WIDTH, 4 * GAME_HEIGHT, { fullscreen = false })

function love.load()
  keys.configure(BINDINGS)
  assets.load()
  scenes.init("scenes/", "game")
end

function love.keypressed(key)
  if keys.toAction(key) then
    BUS:publish("keypressed_" .. keys.toAction(key))
  end
end

function love.keyreleased(key)
  if keys.toAction(key) then
    BUS:publish("keyreleased_" .. keys.toAction(key))
  end
end

function love.mousepressed(x, y, button) 
  local buttonName = button == 1 and "primary" or "secondary"
  BUS:publish("mousepressed_" .. buttonName, { x = x, y = y })
end

function love.mousereleased(x, y, button)
  local buttonName = button == 1 and "primary" or "secondary"
  BUS:publish("mouseclicked_" .. buttonName, { x = x, y = y })
end

function love.resize(w, h)
  return push:resize(w, h)
end

function love.update(dt)
  scenes.update(dt)
end

function love.draw()
  push:start()
  scenes.draw()
  push:finish()
end
