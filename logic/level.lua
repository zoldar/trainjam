local lg = love.graphics
local v = require("lib.vector")
local tiled = require("lib.tiled")
local Train = require("logic.train")

local _M = {}

local function getSwitchedFromTo(directions, switch)
  -- directions.fixed
  -- directions.switchL
  -- directions.switchR

  local switchL = next(directions.switchL) and directions.switchL or directions.fixed
  local switchR = next(directions.switchR) and directions.switchR or directions.fixed

  local switchedFrom

  for k in pairs(switchL) do
    if switchL[k] and switchR[k] and switchL[k] ~= switchR[k] then
      switchedFrom = k
      break
    end
  end

  local activeSwitch = switch == "switchR" and switchR or switchL
  local switchedTo = activeSwitch[switchedFrom]

  return INVERSE_RAIL_2WAY[switchedFrom][switchedTo]
end

local function isSwitching(playerDirection, directions)
  local optionL =
    RAIL_DIRECTIONS[getSwitchedFromTo(directions, "switchL")][INVERSE[playerDirection]]
  local optionR =
    RAIL_DIRECTIONS[getSwitchedFromTo(directions, "switchR")][INVERSE[playerDirection]]

  return optionL and optionR
end

local function getSwitchedTo(playerDirection, directions, switchDirections)
  local comingFrom = INVERSE[playerDirection]
  local switchedTo = switchDirections[comingFrom] or directions[comingFrom]

  return INVERSE_RAIL_1WAY[switchedTo]
end

local levelSpriteMap = {
  tileset_objects = {
    {
      group = "arrows",
      filter = "arrow",
      key = "direction",
    },
    {
      group = "markers",
      filter = "marker",
      key = "color",
    },
    {
      group = "markers",
      filter = "small_marker",
      key = function(tile)
        return "marker_" .. tile.direction
      end,
    },
    {
      group = "markers",
      filter = "dot",
    },
    {
      group = "levers",
      filter = "lever",
      key = "state",
    },
  },
  tileset_cart = {
    {
      group = "trains",
      filter = function(tile)
        return tile.type and tile.state
      end,
      key = function(tile)
        return tile.type .. "_" .. tile.orientation .. "_" .. tile.state
      end,
    },
    {
      group = "trains",
      filter = function(tile)
        return tile.type and not tile.state
      end,
      key = function(tile)
        return tile.type .. "_" .. tile.orientation
      end,
    },
  },
}

function _M.load(game, level)
  local map = tiled.loadMap(require("assets." .. level))
  local ground = {}
  local objects = {}
  local rails = {}
  local levers = {}
  local trains = {}
  local pickups = {}
  local exitMarkers = {}

  local sprites = tiled.getSprites(map.sheets, levelSpriteMap)

  local trainTiles = {}
  local wagonTiles = {}

  for x, row in pairs(map.layers.trains) do
    for y, spriteId in pairs(row) do
      local position = v(x, y)
      local tile = map.byId[spriteId]

      if tile.type == "train_front" then
        trainTiles[tostring(position)] = {
          position = position,
          data = map.byId[spriteId],
        }
      else
        wagonTiles[tostring(position)] = {
          postiion = position,
          data = map.byId[spriteId],
        }
      end
    end
  end

  trains = Train.fromTiles(trainTiles, wagonTiles, sprites.trains)

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

      if map.layers.objects[x] and map.layers.objects[x][y] then
        local tile = map.byId[map.layers.objects[x][y]]
        local sheet = map.sheets[tile.sheetName].image
        local draw = function()
          lg.draw(sheet, tile.sprite, x * TILE_SIZE, y * TILE_SIZE)
        end

        objects[strPosition] = { draw = draw }
      end

      if map.layers.levers[x] and map.layers.levers[x][y] then
        local tile = map.byId[map.layers.levers[x][y]]

        local draw = function()
          sprites.levers[levers[strPosition].state].draw(x * TILE_SIZE, y * TILE_SIZE)
        end

        levers[strPosition] = { draw = draw, state = tile.state }
      end

      if map.layers.pickups[x] and map.layers.pickups[x][y] then
        local tile = map.byId[map.layers.pickups[x][y]]
        local sheet = map.sheets[tile.sheetName].image
        local draw = function()
          local markerOffset = 0
          if game.started and math.sin(game.timer * 10) > 0 then
            markerOffset = -1
          end
          if not game.pickups[strPosition].collected then
            local px, py = x * TILE_SIZE, y * TILE_SIZE
            sprites.markers.yellow.draw(px, py - TILE_SIZE * 0.75 + markerOffset)

            lg.draw(sheet, tile.sprite, px, py)
          end
        end

        pickups[strPosition] = { draw = draw, collected = false }
      end

      if map.layers.exit_markers[x] and map.layers.exit_markers[x][y] then
        local tile = map.byId[map.layers.exit_markers[x][y]]
        local sheet = map.sheets[tile.sheetName].image
        local draw = function()
          local markerOffset = 0
          local mx, my = x * TILE_SIZE, y * TILE_SIZE
          if game.started and math.sin(game.timer * 10) > 0 then
            markerOffset = -1
          end

          if tile.direction == "U" or tile.direction == "D" then
            my = my + markerOffset
          else
            mx = mx + markerOffset
          end

          lg.draw(sheet, tile.sprite, mx, my)
        end

        exitMarkers[#exitMarkers + 1] = { draw = draw }
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
        local leverPosition
        local leverState
        local willSwitch

        if tile.switch then
          leverPosition = position + DIRECTIONS[tile.switch]
          switchDirections = function()
            local lever = levers[tostring(leverPosition)]

            if lever then
              return directions[lever.state]
            else
              return {}
            end
          end
          willSwitch = function(playerDirection)
            return isSwitching(playerDirection, directions)
          end
          leverState = function()
            local lever = levers[tostring(leverPosition)]
            if lever then
              return lever.state
            end
          end
        else
          switchDirections = function()
            return {}
          end
          willSwitch = function()
            return false
          end
          leverState = function()
            return nil
          end
        end

        local draw = function()
          local rx, ry = x * TILE_SIZE, y * TILE_SIZE

          lg.draw(sheet, tile.sprite, rx, ry)
        end

        local drawArrow = function()
          local lever = leverState()

          if lever then
            local rx, ry = x * TILE_SIZE, y * TILE_SIZE
            local nextTurnDirection

            for _, turn in ipairs(game.activeTurns) do
              if turn.position == position then
                nextTurnDirection = turn.direction
              end
            end

            if game.started and math.sin(game.timer * 20) > 0 then
              lg.setColor(1, 1, 1, 0.7)
            end

            if nextTurnDirection then
              local spriteKey =
                getSwitchedTo(nextTurnDirection, directions.fixed, switchDirections())
              sprites.arrows[spriteKey].draw(rx, ry)
            end

            lg.setColor(1, 1, 1, 1)
          end
        end

        rails[strPosition] = {
          draw = draw,
          drawArrow = drawArrow,
          directions = directions.fixed,
          switchDirections = switchDirections,
          switchable = tile.switch,
          leverPosition = leverPosition,
          willSwitch = willSwitch,
        }
      end
    end
  end

  game.levelName = level
  game.map = map
  game.ground = ground
  game.objects = objects
  game.rails = rails
  game.levers = levers
  game.trains = trains
  game.pickups = pickups
  game.sprites = sprites
  game.exitMarkers = exitMarkers
  game.timeLeft = map.props.timer

  return game
end

return _M
