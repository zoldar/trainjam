local lg = love.graphics
local assets = require("assets")

local Train = {}
Train.__index = Train

local buildTail = function(train, wagonTiles, position, dir)
  local tail = {}

  while wagonTiles[tostring(position)] do
    tail[#tail + 1] = {
      state = wagonTiles[tostring(position)].data.state,
      train = train,
      position = position,
      realPosition = position * TILE_SIZE,
      direction = INVERSE[tostring(dir)],
    }

    position = position + dir
  end

  return tail
end

function Train.fromTiles(trainTiles, wagonTiles, sprites)
  local id = 1
  local trains = {}

  for _, t in pairs(trainTiles) do
    local train = Train:new(id, t.position, t.data, sprites)

    local probes

    if t.data.orientation == "horizontal" then
      probes = { DIRECTIONS.left, DIRECTIONS.right }
    else
      probes = { DIRECTIONS.up, DIRECTIONS.down }
    end

    for _, dir in ipairs(probes) do
      local position = train.position + dir
      local nextWagon = wagonTiles[tostring(position)]

      if nextWagon then
        train.direction = INVERSE[tostring(dir)]
        train.tail = buildTail(train, wagonTiles, position, dir)
        break
      end
    end

    trains[#trains + 1] = train
    id = id + 1
  end

  return trains
end

function Train:new(id, position, data, sprites)
  local state = {
    id = id,
    sprites = sprites,
    position = position,
    realPosition = position * TILE_SIZE,
    direction = "up",
    firstTrail = {},
    secondTrail = {},
    speed = TRAIN_SPEED,
    tail = {},
    orientation = data.orientation,
  }

  return setmetatable(state, Train)
end

function Train:nextTurnDistance()
  if self.nextTurn then
    return self.position:distance(self.nextTurn * TILE_SIZE)
  else
    return 9999
  end
end

function Train.turn(wagon, direction)
  if wagon.direction ~= direction then
    wagon.direction = direction
    wagon.realPosition = wagon.position * TILE_SIZE
  end
end

function Train.destroy(wagon)
  local train = wagon.train or wagon

  train.speed = 0
  train.destroyed = true
  assets.sounds.explosion:play()
end

function Train:draw(timer)
  local orientation = ORIENTATION[self.direction]

  local wobbleOffset = 0
  if timer and self.speed > 0 and math.sin(timer * 10) > 0 then
    wobbleOffset = -1
  end

  if self.destroyed then
    lg.setColor(0.5, 0.5, 0.5)
  end

  self.sprites["train_front_" .. orientation].draw(
    self.realPosition.x,
    self.realPosition.y + wobbleOffset
  )

  for _, t in ipairs(self.tail) do
    wobbleOffset = wobbleOffset == -1 and 0 or -1

    local tailOrientation = ORIENTATION[t.direction]
    self.sprites["train_back_" .. tailOrientation .. "_" .. t.state].draw(
      t.realPosition.x,
      t.realPosition.y + wobbleOffset
    )
  end

  lg.setColor(1, 1, 1)
end

return Train
