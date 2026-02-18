local assets = require("assets")
local keys = require("lib.keys")
local v = require("lib.vector")
local camera = require("lib.camera")
local scenes = require("lib.scenes")
local slick = require("vendor.slick.slick")
local tiled = require("lib.tiled")
local lg = love.graphics

local game = { debug = false }

TILE_SIZE = 16
GRID_WIDTH = GAME_WIDTH / TILE_SIZE
GRID_HEIGHT = GAME_HEIGHT / TILE_SIZE

RAIL_DIRECTIONS = {
  U = { down = "up" },
  D = { up = "down" },
  L = { right = "left" },
  R = { left = "right" },
  UD = { down = "up", up = "down" },
  LR = { left = "right", right = "left" },
  RU = { right = "up", up = "right" },
  RD = { right = "down", down = "right" },
  LU = { left = "up", up = "left" },
  LD = { left = "down", down = "left" },
}

INVERSE = {
  up = "down",
  down = "up",
  left = "right",
  right = "left",
}

INVERSE[tostring(DIRECTIONS.up)] = "down"
INVERSE[tostring(DIRECTIONS.down)] = "up"
INVERSE[tostring(DIRECTIONS.left)] = "right"
INVERSE[tostring(DIRECTIONS.right)] = "left"

ORIENTATION = {
  up = "vertical",
  down = "vertical",
  left = "horizontal",
  right = "horizontal",
}

local function loadLevel(level)
  local map = tiled.loadMap(require("assets." .. level))
  local ground = {}
  local rails = {}
  local levers = {}
  local trains = {}

  local leverSheet = map.sheets.tileset_objects.image
  local leverSprites = {}

  for _, tile in ipairs(map.sheets.tileset_objects.tiles) do
    if tile.name == "lever" then
      leverSprites[tile.state] = tile.sprite
    end
  end

  local trainSheet = map.sheets.tileset_cart.image
  local trainSprites = {}

  for _, tile in ipairs(map.sheets.tileset_cart.tiles) do
    if tile.type then
      trainSprites[tile.type .. "_" .. tile.orientation] = tile.sprite
    end
  end

  local drawTrain = function(trainIdx)
    return function()
      local train = trains[trainIdx]
      local orientation = ORIENTATION[train.direction]

      lg.draw(
        trainSheet,
        trainSprites["train_front_" .. orientation],
        train.realPosition.x,
        train.realPosition.y
      )

      for _, t in ipairs(train.tail) do
        local tailOrientation = ORIENTATION[t.direction]
        lg.draw(
          trainSheet,
          trainSprites["train_back_" .. tailOrientation],
          t.realPosition.x,
          t.realPosition.y
        )
      end
    end
  end

  local wagons = {}

  for x, row in pairs(map.layers.trains) do
    for y, spriteId in pairs(row) do
      local tile = map.byId[spriteId]

      if tile.type == "train_front" then
        trains[#trains + 1] = {
          position = v(x, y),
          realPosition = v(x, y) * TILE_SIZE,
          direction = "up",
          speed = 20,
          tail = {},
          orientation = tile.orientation,
          draw = drawTrain(#trains + 1),
        }
      else
        wagons[tostring(v(x, y))] = map.byId[spriteId].orientation
      end
    end
  end

  local buildTail = function(position, dir)
    local tail = {}

    while wagons[tostring(position)] do
      tail[#tail + 1] = {
        position = position,
        realPosition = position * TILE_SIZE,
        direction = INVERSE[tostring(dir)],
      }

      position = position + dir
    end

    return tail
  end

  for _, train in ipairs(trains) do
    local probes

    if train.orientation == "horizontal" then
      probes = { DIRECTIONS.left, DIRECTIONS.right }
    else
      probes = { DIRECTIONS.up, DIRECTIONS.down }
    end

    for _, dir in ipairs(probes) do
      local position = train.position + dir
      local nextWagon = wagons[tostring(position)]

      if nextWagon then
        train.orientation = nil
        train.direction = INVERSE[tostring(dir)]
        train.tail = buildTail(position, dir)
        break
      end
    end
  end

  for x = 0, GRID_WIDTH - 1 do
    for y = 0, GRID_HEIGHT - 1 do
      local position = v(x, y)
      local strPosition = tostring(position)

      if map.layers.ground[x] and map.layers.ground[x][y] then
        local tile = map.byId[map.layers.ground[x][y]]
        local sheet = map.sheets[tile.sheetName].image
        local draw = function()
          lg.draw(sheet, tile.sprite, x * TILE_SIZE, y * TILE_SIZE)
        end

        ground[strPosition] = { draw = draw }
      end

      if map.layers.levers[x] and map.layers.levers[x][y] then
        local tile = map.byId[map.layers.levers[x][y]]

        local draw = function()
          lg.draw(leverSheet, leverSprites[levers[strPosition].state], x * TILE_SIZE, y * TILE_SIZE)
        end

        levers[strPosition] = { draw = draw, state = tile.state }
      end

      if map.layers.rails[x] and map.layers.rails[x][y] then
        local tile = map.byId[map.layers.rails[x][y]]
        local sheet = map.sheets[tile.sheetName].image
        local draw = function()
          lg.draw(sheet, tile.sprite, x * TILE_SIZE, y * TILE_SIZE)
        end

        local directions = {
          fixed = {},
          switchL = {},
          switchR = {},
        }

        for _, dirTable in ipairs({ "fixed", "switchL", "switchR" }) do
          if tile[dirTable] then
            for d in tile[dirTable]:gmatch("([^,]+)") do
              for key, val in pairs(RAIL_DIRECTIONS[d]) do
                directions[dirTable][key] = val
              end
            end
          end
        end

        local switchDirections

        if tile.switch then
          local leverPosition = position + DIRECTIONS[tile.switch]
          switchDirections = function()
            return directions[levers[tostring(leverPosition)].state]
          end
        else
          switchDirections = function()
            return {}
          end
        end

        rails[strPosition] =
          { draw = draw, directions = directions.fixed, switchDirections = switchDirections }
      end
    end
  end

  game.map = map
  game.ground = ground
  game.rails = rails
  game.levers = levers
  game.trains = trains
end

local function turnWagon(wagon)
  local rail = game.rails[tostring(wagon.position)]

  if rail then
    local comingFrom = INVERSE[wagon.direction]

    local exit = rail.switchDirections()[comingFrom] or rail.directions[comingFrom]

    if exit then
      wagon.direction = exit
      wagon.realPosition = wagon.position * TILE_SIZE
    end
  end
end

local function moveWagon(wagon, speed, dt)
  wagon.realPosition = wagon.realPosition + DIRECTIONS[wagon.direction] * speed * dt
  local position = wagon.realPosition / TILE_SIZE
  position = v(math.floor(position.x), math.floor(position.y))

  if position.x ~= wagon.position.x or position.y ~= wagon.position.y then
    turnWagon(wagon)
  end

  wagon.position = v(math.floor(position.x), math.floor(position.y))
end

local function moveTrain(train, dt)
  moveWagon(train, train.speed, dt)

  for _, wagon in ipairs(train.tail) do
    moveWagon(wagon, train.speed, dt)
  end
end

function game:init()
  game.camera = camera:new()
  game.world = slick.newWorld(GAME_WIDTH, GAME_HEIGHT)

  loadLevel("level1")

  game.debugListener = BUS:subscribe("keypressed_debug", function()
    game.debug = not game.debug
  end)
end

function game:update(dt)
  for _, train in ipairs(game.trains) do
    moveTrain(train, dt)
  end
end

function game:draw()
  game.camera:attach()

  for _, g in pairs(game.ground) do
    g.draw()
  end

  for _, r in pairs(game.rails) do
    r.draw()
  end

  for _, l in pairs(game.levers) do
    l.draw()
  end

  for _, t in ipairs(game.trains) do
    t.draw()
  end

  lg.print("WIP")

  if game.debug then
    slick.drawWorld(game.world)
  end

  game.camera:detach()
end

function game:close()
  BUS:unsubscribe(game.debugListener)
end

return game
