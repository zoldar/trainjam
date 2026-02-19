local tiled = require("lib.tiled")
local v = require("lib.vector")
local lg = love.graphics

local _M = {}

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

function _M.load(game, level)
  local map = tiled.loadMap(require("assets." .. level))
  local playerPosition = v(map.props.playerTrainX, map.props.playerTrainY)
  local ground = {}
  local rails = {}
  local levers = {}
  local trains = {}
  local playerTrain

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
      local position = v(x, y)
      local tile = map.byId[spriteId]

      if tile.type == "train_front" then
        local idx = #trains + 1
        trains[idx] = {
          id = idx,
          position = position,
          realPosition = position * TILE_SIZE,
          direction = "up",
          speed = TRAIN_SPEED,
          tail = {},
          orientation = tile.orientation,
          draw = drawTrain(#trains + 1),
        }

        if position == playerPosition then
          playerTrain = trains[idx]
        end
      else
        wagons[tostring(position)] = map.byId[spriteId].orientation
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

        rails[strPosition] = {
          draw = draw,
          directions = directions.fixed,
          switchDirections = switchDirections,
          switchable = tile.switch,
          leverPosition = leverPosition,
        }
      end
    end
  end

  game.map = map
  game.ground = ground
  game.rails = rails
  game.levers = levers
  game.trains = trains
  game.playerTrain = playerTrain

  return game
end

return _M
