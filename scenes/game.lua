local lg = love.graphics
local assets = require("assets")
local v = require("lib.vector")
local camera = require("lib.camera")
local scenes = require("lib.scenes")
local collisions = require("lib.collisions")
local level = require("logic.level")
local Train = require("logic.train")

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

local function probe(startPosition, startDirection, pathLength)
  pathLength = pathLength or 1
  local prevDirection = startDirection
  local position, direction = probeRail(startPosition, startDirection)
  local canContinue = true
  local trail = {}

  if not game.rails[tostring(position)] then
    return position, prevDirection, trail, false
  end

  local positionBeforeProbe = v(position.x, position.y)

  while pathLength > 0 do
    trail[#trail + 1] = { position = position, from = prevDirection, to = direction }
    prevDirection = direction
    position, direction, canContinue = probeRail(position, direction)

    if not canContinue or position == positionBeforeProbe then
      return position, prevDirection, trail, false
    end

    if game.rails[tostring(position)].willSwitch(prevDirection) then
      pathLength = pathLength - 1
    end
  end

  return position, prevDirection, trail, true
end

local function updateFocus()
  local focus

  for _, t in ipairs(game.trains) do
    local rail = game.rails[tostring(t.nextTurn or "none")]
    local nextSwitchable = rail and rail.switchable

    if
      nextSwitchable
      and not t.slowTimerDone
      and (not focus or t:nextTurnDistance() < focus:nextTurnDistance())
    then
      focus = t
    end
  end

  game.focus = focus
end

local function updateNextTurn(wagon)
  local currentNextTurn = wagon.nextTurn
  wagon.nextTurn, wagon.nextTurnDirection, wagon.firstTrail =
    probe(wagon.position, wagon.direction, 1)
  _, _, wagon.secondTrail = probe(wagon.position, wagon.direction, 2)

  if currentNextTurn ~= wagon.nextTurn and wagon.slowTimerDone then
    wagon.slowTimerDone = false
  end
end

local function turnWagon(wagon)
  local rail = game.rails[tostring(wagon.position)]

  if rail then
    local comingFrom = INVERSE[wagon.direction]

    local exit = rail.switchDirections()[comingFrom] or rail.directions[comingFrom]

    if exit then
      Train.turn(wagon, exit)
    else
      Train.destroy(wagon)
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
  if wagon.train and wagon.state == "empty" then
    for _, d in ipairs(ORTHOGONAL[wagon.direction]) do
      local position = wagon.position + d
      local pickup = game.pickups[tostring(position)]

      if pickup and not pickup.collected then
        pickup.collected = true
        wagon.state = "full"
        assets.sounds.pickup:play()
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
    updateNextTurn(wagon)
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
        local wagonId = wagon.id or wagon.train.id
        local otherWagonId = otherWagon.id or otherWagon.train.id

        if wagonId ~= otherWagonId then
          local w, h = TILE_SIZE - 2 * HITBOX_SHRINK, TILE_SIZE - 2 * HITBOX_SHRINK
          local x1, y1 = wagon.realPosition.x + HITBOX_SHRINK, wagon.realPosition.y + HITBOX_SHRINK
          local x2, y2 =
            otherWagon.realPosition.x + HITBOX_SHRINK, otherWagon.realPosition.y + HITBOX_SHRINK

          if collisions.aabb(x1, y1, w, h, x2, y2, w, h) then
            train.speed = 0
            train.destroyed = true
            assets.sounds.explosion:play()
          end
        end
      end)
    end
  end)
end

local function getActiveTurns()
  local turns = {}

  for _, train in ipairs(game.trains) do
    if train.nextTurn and game.focus and train.id == game.focus.id then
      local rails = game.rails[tostring(train.nextTurn)]
      if rails and rails.switchable then
        turns[#turns + 1] = { position = train.nextTurn, direction = train.nextTurnDirection }
      end
    end
  end

  return turns
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

local function allTrainsOutOfMap()
  local allOut = true

  for _, train in ipairs(game.trains) do
    if not isOutOfMap(train) then
      allOut = false
      break
    end
  end

  return allOut
end

local function wagonsFull(train)
  local allFull = true

  for _, t in ipairs(train.tail) do
    if t.state == "empty" then
      allFull = false
      break
    end
  end

  return allFull
end

local function anyWagonsFull()
  local anyFull = false

  for _, train in ipairs(game.trains) do
    if wagonsFull(train) then
      anyFull = true
      break
    end
  end

  return anyFull
end

local function allWagonsFull()
  local allFull = true

  for _, train in ipairs(game.trains) do
    if not wagonsFull(train) then
      allFull = false
      break
    end
  end

  return allFull
end

local function anyTrainDestroyed()
  local anyDestroyed = false

  for _, train in ipairs(game.trains) do
    if train.destroyed then
      anyDestroyed = true
      break
    end
  end

  return anyDestroyed
end

local function switchLever(x, y, tilePosition)
  if not tilePosition then
    x, y = math.floor(x / TILE_SIZE), math.floor(y / TILE_SIZE)
  end

  local rails = game.rails[tostring(v(x, y))]

  if rails and rails.switchable then
    local lever = game.levers[tostring(rails.leverPosition)]
    lever.state = lever.state == "switchL" and "switchR" or "switchL"
    for _, train in ipairs(game.trains) do
      updateNextTurn(train)
    end
    assets.sounds.switch:clone():play()
  end
end

local function drawTrail(train, trainIdx)
  local r, g, b = unpack(TRAIL_COLORS[trainIdx])

  if train.firstTrail and train.speed > 0 then
    for _, t in ipairs(train.firstTrail) do
      if not game.rails[tostring(t.position)].switchable then
        lg.setColor(r, g, b, 0.5)

        game.sprites.markers["marker_" .. t.to].draw(
          t.position.x * TILE_SIZE,
          t.position.y * TILE_SIZE
        )

        lg.setColor(1, 1, 1, 1)
      end
    end

    local opacity = 0.5

    if #train.secondTrail > #train.firstTrail then
      for idx = #train.firstTrail, #train.secondTrail do
        local position = train.secondTrail[idx].position
        local direction = train.secondTrail[idx].to

        if not game.rails[tostring(position)].switchable then
          lg.setColor(r, g, b, opacity)

          game.sprites.markers["marker_" .. direction].draw(
            position.x * TILE_SIZE,
            position.y * TILE_SIZE
          )

          lg.setColor(1, 1, 1, 1)

          opacity = opacity - 0.1
        end

        if opacity <= 0 then
          break
        end
      end
    end
  end
end

-- local function drawMarkers()
--   if game.playerTrain then
--     local markerOffset = 0
--     if game.started and math.sin(game.timer * 10) > 0 then
--       markerOffset = -1
--     end
--
--     local playerMarker = game.playerTrain.realPosition + DIRECTIONS.up * TILE_SIZE
--     playerMarker.y = playerMarker.y + markerOffset
--
--     lg.setColor(1, 1, 1, 0.6)
--
--     game.sprites.markers.white.draw(playerMarker.x, playerMarker.y)
--
--     lg.setColor(1, 1, 1, 1)
--   end
-- end

local function drawIntro()
  lg.printf("TRAIN JAM", assets.fonts.logo, 0, 0, GAME_WIDTH, "center")

  lg.printf(
    "PRESS SPACE TO CONTINUE",
    assets.fonts.standard,
    0,
    GAME_HEIGHT - assets.fonts.standard:getHeight() - 30,
    GAME_WIDTH,
    "center"
  )
end

local function drawOptionButton()
  lg.printf("OPTIONS", assets.fonts.tiny, 4, 2, GAME_WIDTH, "left")
end

local function optionsClicked(x, y)
  local w = assets.fonts.tiny:getWidth("OPTIONS") + 8
  local h = assets.fonts.tiny:getHeight() + 4

  return x > 0 and x < w and y > 0 and y < h
end

local function updateSlowMode(dt)
  updateFocus()

  if game.focus and #game.focus.firstTrail < 2 and game.slowTimer > 0 then
    game.slowTimer = game.slowTimer - dt
    game.slow = true
  else
    if game.slow then
      game.focus.slowTimerDone = true
      game.slowTimer = SLOW_TIME
    end

    game.slow = false
  end
end

function game:init(levelName)
  game = { activeTurns = {}, slow = false, slowTimer = SLOW_TIME, focus = nil }

  game.camera = camera:new()

  levelName = levelName or "level0"

  game = level.load(game, levelName)

  game.mouseListener = BUS:subscribe("mouseclicked_primary", function(pos)
    local lx, ly = game.camera:worldCoords(pos.x, pos.y)
    if game.started then
      if game.levelName == "level0" then
        scenes.switch("game", FIRST_LEVEL)
      else
        if optionsClicked(lx, ly) then
          scenes.push("menu", game.levelName, game.started)
          game.started = false
        else
          switchLever(lx, ly)
        end
      end
    end
  end)

  game.actionListener = BUS:subscribe("keypressed_use", function()
    if game.started and game.levelName == "level0" then
      scenes.switch("game", FIRST_LEVEL)
    end
  end)

  game.menuListener = BUS:subscribe("keypressed_menu", function()
    if game.levelName ~= "level0" then
      if scenes.currentFocus() == "menu" then
        scenes.pop()
        game.started = true
      else
        scenes.push("menu", game.levelName, game.started)
        game.started = false
      end
    end
  end)

  self.gameStartedListener = BUS:subscribe("game_started", function()
    game.started = true
  end)

  game.timer = 0
  game.started = false

  for _, train in ipairs(game.trains) do
    updateNextTurn(train)
  end
end

function game:update(dt)
  local moveDt = dt
  if game.slow then
    moveDt = SLOW_SPEED_FACTOR * dt
  end

  game.timer = game.timer + moveDt

  if game.timeLeft then
    local newTimeLeft = game.timeLeft - moveDt
    if newTimeLeft <= 9 and math.ceil(newTimeLeft) < math.ceil(game.timeLeft) then
      assets.sounds.warning:play()
    end
    game.timeLeft = newTimeLeft
  end

  if game.levelName ~= "level0" and not game.started then
    scenes.push("countdown")
    for _, train in ipairs(game.trains) do
      updateNextTurn(train)
    end
  elseif not game.started then
    game.started = true
  end

  for idx = #game.trains, 1, -1 do
    local train = game.trains[idx]

    moveTrain(train, moveDt)
    checkCollisions(train)
  end

  game.activeTurns = getActiveTurns()

  game.wagonsFull = anyWagonsFull()

  if game.levelName ~= "level0" then
    updateSlowMode(dt)
  end

  if anyTrainDestroyed() then
    scenes.push("lost", "crashed", game.levelName)
  end

  if game.timeLeft and game.timeLeft <= 0 then
    scenes.push("lost", "timeout", game.levelName)
  end

  if allTrainsOutOfMap() then
    if allWagonsFull() then
      scenes.push("won", game.levelName)
    else
      scenes.push("lost", "freight_missing", game.levelName)
    end
  end
end

function game:draw()
  game.camera:attach()

  for _, g in pairs(game.ground) do
    g.draw()
  end

  for _, o in pairs(game.objects) do
    o.draw()
  end

  for _, r in pairs(game.rails) do
    r.draw()
  end

  -- for _, l in pairs(game.levers) do
  --   l.draw()
  -- end

  for idx, t in ipairs(game.trains) do
    if game.levelName ~= "level0" and game.focus and game.focus.id == t.id then
      drawTrail(t, idx)
    end
    t:draw(game.timer)
  end

  for _, p in pairs(game.pickups) do
    p.draw()
  end

  if game.wagonsFull then
    for _, m in ipairs(game.exitMarkers) do
      m.draw()
    end
  end

  if game.slow then
    lg.setColor(0, 0, 0, 0.3)
    lg.rectangle("fill", 0, 0, GAME_WIDTH, GAME_HEIGHT)
    lg.setColor(1, 1, 1, 1)

    for _, r in pairs(game.rails) do
      r.drawArrow()
    end

    drawTrail(game.focus, 1)

    game.focus:draw(game.timer)
  end
  -- drawMarkers()

  if game.timeLeft then
    if game.timeLeft <= 9 then
      lg.setColor(217 / 255, 53 / 255, 50 / 255)
    end
    lg.printf(
      tostring(math.max(math.ceil(game.timeLeft), 0)),
      assets.fonts.standard,
      0,
      3,
      GAME_WIDTH,
      "center"
    )
    lg.setColor(1, 1, 1)
  end

  if game.levelName == "level0" then
    drawIntro()
  else
    drawOptionButton()
  end

  game.camera:detach()
end

function game:close()
  BUS:unsubscribe(game.mouseListener)
  BUS:unsubscribe(game.actionListener)
  BUS:unsubscribe(game.gameStartedListener)
  BUS:unsubscribe(game.menuListener)
end

return game
