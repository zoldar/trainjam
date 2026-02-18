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

TRAIN_SPEED = 40

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

ORTHOGONAL = {
  up = DIRECTIONS.right,
  down = DIRECTIONS.right,
  left = DIRECTIONS.up,
  right = DIRECTIONS.down,
}

local function getSwitchedFrom(directions)
  -- directions.fixed
  -- directions.switchL
  -- directions.switchR

  local switchL = next(directions.switchL) and directions.switchL or directions.fixed
  local switchR = next(directions.switchR) and directions.switchR or directions.fixed

  local output

  for k in pairs(switchL) do
    if switchL[k] and switchR[k] and switchL[k] ~= switchR[k] then
      output = k
      break
    end
  end

  return output
end

local function loadLevel(level)
  local map = tiled.loadMap(require("assets." .. level))
  local ground = {}
  local rails = {}
  local levers = {}
  local trains = {}

  local objectSheet = map.sheets.tileset_objects.image
  local leverSprites = {}
  local arrowSprites = {}

  for _, tile in ipairs(map.sheets.tileset_objects.tiles) do
    if tile.name == "lever" then
      leverSprites[tile.state] = tile.sprite
    elseif tile.name == "arrow" then
      arrowSprites[tile.direction] = tile.sprite
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
        local idx = #trains + 1
        trains[idx] = {
          id = idx,
          position = v(x, y),
          realPosition = v(x, y) * TILE_SIZE,
          direction = "up",
          speed = TRAIN_SPEED,
          tail = {},
          orientation = tile.orientation,
          draw = drawTrain(#trains + 1),
        }
      else
        wagons[tostring(v(x, y))] = map.byId[spriteId].orientation
      end
    end
  end

  local buildTail = function(train, position, dir)
    local tail = {}

    while wagons[tostring(position)] do
      tail[#tail + 1] = {
        trainId = train.id,
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
        train.tail = buildTail(train, position, dir)
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
          lg.draw(
            objectSheet,
            leverSprites[levers[strPosition].state],
            x * TILE_SIZE,
            y * TILE_SIZE
          )
        end

        levers[strPosition] = { draw = draw, state = tile.state }
      end

      if map.layers.rails[x] and map.layers.rails[x][y] then
        local tile = map.byId[map.layers.rails[x][y]]
        local sheet = map.sheets[tile.sheetName].image
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
        local switchedFrom
        local leverPosition

        if tile.switch then
          switchedFrom = getSwitchedFrom(directions)
          leverPosition = position + DIRECTIONS[tile.switch]
          switchDirections = function()
            return directions[levers[tostring(leverPosition)].state]
          end
        else
          switchDirections = function()
            return {}
          end
        end

        local draw = function()
          if tile.switch then
            local arrowDirection = switchDirections()[switchedFrom]
              or directions.fixed[switchedFrom]
            local arrowPosition = leverPosition + ORTHOGONAL[tile.switch]

            lg.draw(
              objectSheet,
              arrowSprites[arrowDirection],
              arrowPosition.x * TILE_SIZE,
              arrowPosition.y * TILE_SIZE
            )
          end
          lg.draw(sheet, tile.sprite, x * TILE_SIZE, y * TILE_SIZE)
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

    if exit and wagon.direction ~= exit then
      wagon.direction = exit
      wagon.realPosition = wagon.position * TILE_SIZE
    elseif not exit then
      local train = wagon.trainId and game.trains[wagon.trainId] or wagon

      train.speed = 0
      train.destroyed = true
    end
  end
end

local function roundByDirection(position, direction)
  local x, y = position.x, position.y

  if direction == "left" then
    x, y = math.ceil(x), math.floor(y)
  elseif direction == "right" then
    x, y = math.floor(x), math.floor(y)
  elseif direction == "up" then
    x, y = math.floor(x), math.ceil(y)
  else
    x, y = math.floor(x), math.floor(y)
  end

  return v(x, y)
end

local function moveWagon(wagon, speed, dt)
  wagon.realPosition = wagon.realPosition + DIRECTIONS[wagon.direction] * speed * dt
  local position = wagon.realPosition / TILE_SIZE

  position = roundByDirection(position, wagon.direction)

  if position.x ~= wagon.position.x or position.y ~= wagon.position.y then
    wagon.position = position
    turnWagon(wagon)
  else
    wagon.position = position
  end
end

local function moveTrain(train, dt)
  moveWagon(train, train.speed, dt)

  for _, wagon in ipairs(train.tail) do
    moveWagon(wagon, train.speed, dt)
  end
end

local function eachTrainWagon(train, func)
  func(train)
  for _, wagon in ipairs(train.tail) do
    func(wagon)
  end
end

local function eachWagon(func)
  for _, train in ipairs(game.trains) do
    eachTrainWagon(train, func)
  end
end

-- AABB
local function collides(x1, y1, w1, h1, x2, y2, w2, h2)
  return x1 < x2 + w2 and x1 + w1 > x2 and y1 < y2 + h2 and y1 + h1 > y2
end

local function checkCollisions(train)
  eachTrainWagon(train, function(wagon)
    if not train.destroyed then
      eachWagon(function(otherWagon)
        local wagonId = wagon.id or wagon.trainId
        local otherWagonId = otherWagon.id or otherWagon.trainId

        if wagonId ~= otherWagonId then
          local w, h = TILE_SIZE, TILE_SIZE
          local x1, y1 = wagon.realPosition.x, wagon.realPosition.y
          local x2, y2 = otherWagon.realPosition.x, otherWagon.realPosition.y

          if collides(x1, y1, w, h, x2, y2, w, h) then
            train.speed = 0
            train.destroyed = true
          end
        end
      end)
    end
  end)
end

local function trainDestroyed()
  for _, train in ipairs(game.trains) do
    if train.destroyed then
      return true
    end
  end

  return false
end

local function isOutOfMap(train)
  local allOut = true

  local x1, y1 = 0, 0
  local w1, h1 = GAME_WIDTH, GAME_HEIGHT

  eachTrainWagon(train, function(wagon)
    local x2, y2 = wagon.realPosition.x, wagon.realPosition.y
    local w2, h2 = TILE_SIZE, TILE_SIZE

    if collides(x1, y1, w1, h1, x2, y2, w2, h2) then
      allOut = false
    end
  end)

  return allOut
end

local function switchLever(x, y)
  x, y = math.floor(x / TILE_SIZE), math.floor(y / TILE_SIZE)

  local lever = game.levers[tostring(v(x, y))]

  if lever then
    lever.state = lever.state == "switchL" and "switchR" or "switchL"
  end
end

function game:init(level)
  game.camera = camera:new()
  game.world = slick.newWorld(GAME_WIDTH, GAME_HEIGHT)

  loadLevel(level or "level1")

  game.mouseListener = BUS:subscribe("mouseclicked_primary", function(position)
    local x, y = game.camera:worldCoords(position.x, position.y)
    switchLever(x, y)
  end)

  game.debugListener = BUS:subscribe("keypressed_debug", function()
    game.debug = not game.debug
  end)

  game.started = false
end

function game:update(dt)
  if not game.started then
    game.started = true
    scenes.push("countdown")
  end

  for idx = #game.trains, 1, -1 do
    local train = game.trains[idx]

    moveTrain(train, dt)
    checkCollisions(train)
    if isOutOfMap(train) then
      INSPECT("REMOVING TRAIN")
      table.remove(game.trains, idx)
    end
  end

  if trainDestroyed() then
    scenes.push("lost")
  end

  if #game.trains == 0 then
    scenes.push("won")
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
  BUS:unsubscribe(game.mouseListener)
end

return game
