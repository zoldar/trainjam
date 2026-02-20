local assets = require("assets")
local keys = require("lib.keys")
local v = require("lib.vector")
local camera = require("lib.camera")
local scenes = require("lib.scenes")
local collisions = require("lib.collisions")
local level = require("logic.level")
local lg = love.graphics

local game = {}

local function probeRail(position, direction)
  local newPosition = position + DIRECTIONS[direction]
  local rail = game.rails[tostring(newPosition)]

  if rail then
    local comingFrom = INVERSE[direction]

    local exit = rail.switchDirections()[comingFrom] or rail.directions[comingFrom]

    if exit then
      return newPosition, exit, true
    else
      return position, direction, false
    end
  else
    return position, direction, false
  end
end

local function probe(startPosition, startDirection, fullPath)
  local position, direction = probeRail(startPosition, startDirection)
  local canContinue = true

  if not game.rails[tostring(position)] then
    return position, false
  end

  while fullPath or not game.rails[tostring(position)].switchable do
    position, direction, canContinue = probeRail(position, direction)

    if not canContinue then
      return position, false
    end
  end

  return position, true
end

local function turnWagon(wagon)
  local rail = game.rails[tostring(wagon.position)]

  if rail then
    local comingFrom = INVERSE[wagon.direction]

    local exit = rail.switchDirections()[comingFrom] or rail.directions[comingFrom]

    if rail.switchable and wagon.id then
      wagon.switchTried = false
    end

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

local function collectPickup(wagon)
  if wagon.trainId and wagon.state == "empty" then
    for _, d in ipairs(ORTHOGONAL[wagon.direction]) do
      local position = wagon.position + d
      local pickup = game.pickups[tostring(position)]

      if pickup and not pickup.collected then
        pickup.collected = true
        wagon.state = "full"
      end
    end
  end
end

local function moveWagon(wagon, speed, dt)
  wagon.realPosition = wagon.realPosition + DIRECTIONS[wagon.direction] * speed * dt
  local position = wagon.realPosition / TILE_SIZE

  position = roundByDirection(position, wagon.direction)

  if position.x ~= wagon.position.x or position.y ~= wagon.position.y then
    wagon.position = position
    turnWagon(wagon)
    wagon.nextTurn = probe(wagon.position, wagon.direction)
    collectPickup(wagon)
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

local function checkCollisions(train)
  eachTrainWagon(train, function(wagon)
    if not train.destroyed then
      eachWagon(function(otherWagon)
        local wagonId = wagon.id or wagon.trainId
        local otherWagonId = otherWagon.id or otherWagon.trainId

        if wagonId ~= otherWagonId then
          local w, h = TILE_SIZE - 2 * HITBOX_SHRINK, TILE_SIZE - 2 * HITBOX_SHRINK
          local x1, y1 = wagon.realPosition.x + HITBOX_SHRINK, wagon.realPosition.y + HITBOX_SHRINK
          local x2, y2 =
            otherWagon.realPosition.x + HITBOX_SHRINK, otherWagon.realPosition.y + HITBOX_SHRINK

          if collisions.aabb(x1, y1, w, h, x2, y2, w, h) then
            train.speed = 0
            train.destroyed = true
          end
        end
      end)
    end
  end)
end

local function isOutOfMap(train)
  local allOut = true

  local x1, y1 = 0, 0
  local w1, h1 = GAME_WIDTH, GAME_HEIGHT

  eachTrainWagon(train, function(wagon)
    local x2, y2 = wagon.realPosition.x, wagon.realPosition.y
    local w2, h2 = TILE_SIZE, TILE_SIZE

    if collisions.aabb(x1, y1, w1, h1, x2, y2, w2, h2) then
      allOut = false
    end
  end)

  return allOut
end

local function wagonsFull()
  local allFull = true

  for _, t in ipairs(game.playerTrain.tail) do
    if t.state == "empty" then
      allFull = false
      break
    end
  end

  return allFull
end

local function switchLever(x, y, tilePosition)
  if not tilePosition then
    x, y = math.floor(x / TILE_SIZE), math.floor(y / TILE_SIZE)
  end

  local lever = game.levers[tostring(v(x, y))]

  if lever then
    lever.state = lever.state == "switchL" and "switchR" or "switchL"
  end
end

local function switchNextLever(train)
  local nextSwitch = game.rails[tostring(train.nextTurn)]
  if nextSwitch and nextSwitch.switchable then
    switchLever(nextSwitch.leverPosition.x, nextSwitch.leverPosition.y, true)
  end
end

local function maybeSwitchLever(train)
  if not train.switchTried and train.nextTurn and train.position:distance(train.nextTurn) >= 2 then
    if love.math.random(1, LEVER_SWITCH_FACTOR) == 1 then
      switchNextLever(train)
    end

    train.switchTried = true
  end
end

local function drawMarkers()
  local markerOffset = 0
  if game.started and math.sin(game.timer * 10) > 0 then
    markerOffset = -1
  end

  local playerMarker = game.playerTrain.realPosition + DIRECTIONS.up * TILE_SIZE
  playerMarker.y = playerMarker.y + markerOffset

  lg.setColor(1, 1, 1, 0.6)

  lg.draw(
    game.map.sheets.tileset_objects.image,
    game.markerSprites.white,
    playerMarker.x,
    playerMarker.y
  )

  lg.setColor(1, 1, 1, 1)
end

function game:init(levelName)
  game.camera = camera:new()

  game = level.load(game, levelName or "level2")

  game.mouseListener = BUS:subscribe("mouseclicked_primary", function()
    switchNextLever(game.playerTrain)
  end)

  game.actionListener = BUS:subscribe("keypressed_use", function()
    switchNextLever(game.playerTrain)
  end)

  game.timer = 0
  game.started = false
end

function game:update(dt)
  game.timer = game.timer + dt
  if not game.started then
    game.started = true
    scenes.push("countdown")
    game.playerTrain.nextTurn = probe(game.playerTrain.position, game.playerTrain.direction)
  end

  for idx = #game.trains, 1, -1 do
    local train = game.trains[idx]

    moveTrain(train, dt)
    checkCollisions(train)

    if train.id ~= game.playerTrain.id then
      maybeSwitchLever(train)
    end
  end

  game.wagonsFull = wagonsFull()

  if game.playerTrain.destroyed then
    scenes.push("lost")
  end

  if isOutOfMap(game.playerTrain) then
    if game.wagonsFull then
      scenes.push("won")
    else
      scenes.push("lost")
    end
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

  for _, p in pairs(game.pickups) do
    p.draw()
  end

  if game.wagonsFull then
    for _, m in ipairs(game.exitMarkers) do
      m.draw()
    end
  end

  drawMarkers()

  lg.print("WIP")

  game.camera:detach()
end

function game:close()
  BUS:unsubscribe(game.mouseListener)
  BUS:unsubscribe(game.actionListener)
end

return game
