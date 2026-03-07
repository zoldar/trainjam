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
push:setupScreen(
  GAME_WIDTH,
  GAME_HEIGHT,
  WINDOW_SCALE_FACTOR * GAME_WIDTH,
  WINDOW_SCALE_FACTOR * GAME_HEIGHT,
  { fullscreen = false, pixelperfect = true, resizable = true }
)

local function load()
  keys.configure(BINDINGS)
  assets.load()
  scenes.init("scenes/", "game")
end

love.load = load

local function keypressed(key)
  if keys.toAction(key) then
    BUS:publish("keypressed_" .. keys.toAction(key))
  end
end

love.keypressed = keypressed

local function keyreleased(key)
  if keys.toAction(key) then
    BUS:publish("keyreleased_" .. keys.toAction(key))
  end
end

love.keyreleased = keyreleased

local function mousepressed(x, y, button)
  local buttonName = button == 1 and "primary" or "secondary"
  BUS:publish("mousepressed_" .. buttonName, { x = x, y = y })
end

love.mousepressed = mousepressed

local function mousereleased(x, y, button)
  local buttonName = button == 1 and "primary" or "secondary"
  BUS:publish("mouseclicked_" .. buttonName, { x = x, y = y })
end

love.mousereleased = mousereleased

local function resize(w, h)
  return push:resize(w, h)
end

love.resize = resize

local function update(dt)
  scenes.update(dt)
end

love.update = update

local function draw()
  push:start()
  scenes.draw()
  push:finish()
end

love.draw = draw
