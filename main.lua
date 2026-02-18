local screen = require("lib.screen")
local assets = require("assets")
local v = require("lib.vector")
local Bus = require("lib.bus")
local scenes = require("lib.scenes")
local keys = require("lib.keys")
local inspect = require("vendor.inspect")

GAME_WIDTH, GAME_HEIGHT = 320, 240

BINDINGS = {
  use = { "space" },
  left = { "left", "a" },
  right = { "right", "d" },
  up = { "up", "w" },
  down = { "s" },
  debug = { "d" },
}

DIRECTIONS = {
  left = v(-1, 0),
  right = v(1, 0),
  up = v(0, -1),
  down = v(0, 1),
}

INSPECT = function(x)
  print(inspect(x))
  return x
end

BUS = Bus:new()

function love.load()
  screen.load(GAME_WIDTH, GAME_HEIGHT)
  keys.configure(BINDINGS)
  assets.load()
  scenes.init("scenes/", "game")
end

function love.keypressed(key)
  if key == "escape" or key == "q" then
    love.event.quit()
  elseif keys.toAction(key) then
    BUS:publish("keypressed_" .. keys.toAction(key))
  end
end

function love.keyreleased(key)
  if keys.toAction(key) then
    BUS:publish("keyreleased_" .. keys.toAction(key))
  end
end

function love.mousereleased(x, y, button)
  local buttonName = button == 1 and "primary" or "secondary"
  BUS:publish("mouseclicked_" .. buttonName, { x = x, y = y })
end

function love.resize(w, h)
  screen.resize(w, h)
end

function love.update(dt)
  scenes.update(dt)
end

function love.draw()
  scenes.draw()
end
