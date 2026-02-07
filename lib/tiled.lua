local slick = require("vendor.slick.slick")

local _M = {}

local function toSlickShape(shape, tag)
  tag = slick.newTag(tag)
  local slickShape

  if shape.type == "rectangle" then
    slickShape =
      slick.newRectangleShape(shape.position.x, shape.position.y, shape.width, shape.height, tag)
  elseif shape.type == "polygon" then
    local vertices = {}
    for _, vertex in ipairs(shape.points) do
      vertices[#vertices + 1] = vertex.x
      vertices[#vertices + 1] = vertex.y
    end

    slickShape = slick.newPolygonShape(vertices, tag)
  end

  return slickShape
end

local function toSlickShapeGroup(shapes, tag)
  local slickShapes = {}

  for idx, shape in ipairs(shapes) do
    slickShapes[idx] = toSlickShape(shape, tag)
  end

  return slick.newShapeGroup(unpack(slickShapes))
end

local function loadCamera(map, data)
  if data.properties["camera"] then
    map.camera.mode = data.properties["camera"]
  end

  if data.properties["cameraBoundsX"] then
    map.camera.bounds.x = data.properties["cameraBoundsX"]
  end

  if data.properties["cameraBoundsY"] then
    map.camera.bounds.y = data.properties["cameraBoundsY"]
  end

  if data.properties["cameraBoundsW"] then
    map.camera.bounds.width = data.properties["cameraBoundsW"]
  end

  if data.properties["cameraBoundsH"] then
    map.camera.bounds.height = data.properties["cameraBoundsH"]
  end

  return map
end

local function loadBackground(map, layer)
  map.bg = love.graphics.newImage("assets/" .. layer.image)
  map.bgOffset = { x = layer.offsetx, y = layer.offsety }

  return map
end

local function loadBounds(map, layer)
  for _, object in ipairs(layer.objects) do
    if object.shape == "polygon" then
      local points = {}
      for idx, v in ipairs(object.polygon) do
        points[idx] = { x = object.x + v.x, y = object.y + v.y }
      end

      map.bounds[#map.bounds + 1] = {
        type = "polygon",
        points = points,
      }
    elseif object.shape == "rectangle" then
      map.bounds[#map.bounds + 1] = {
        type = "rectangle",
        position = { x = object.x, y = object.y },
        width = object.width,
        height = object.height,
      }
    end
  end

  map.bounds = toSlickShapeGroup(map.bounds, "wall")

  return map
end

local function loadEntrances(map, layer)
  for _, object in ipairs(layer.objects) do
    map.entrances[object.name] =
      { x = object.x, y = object.y, direction = object.properties["direction"] }
  end

  return map
end

local function loadExits(map, layer)
  local slickTag = slick.newTag("exit")

  for idx, object in ipairs(layer.objects) do
    local exit = {
      room = object.name,
      position = { x = object.x, y = object.y },
      width = object.width,
      height = object.height,
    }

    exit.shape = slick.newRectangleShape(0, 0, exit.width, exit.height, slickTag)

    map.exits[idx] = exit
  end

  return map
end

local function loadPointsOfInterest(map, layer)
  for _, object in ipairs(layer.objects) do
    if object.name == "player_spawn" then
      map.spawnPoint = { x = object.x, y = object.y }
    end
  end

  return map
end

function _M.load(path)
  local data = require(path)

  local map = {
    bounds = {},
    spawnPoint = { x = 0, y = 0 },
    bg = "",
    entrances = {},
    exits = {},
    camera = {
      mode = nil,
      bounds = {
        x = 0,
        y = 0,
        width = 320,
        height = 240,
      },
    },
  }

  map = loadCamera(map, data)

  for _, layer in ipairs(data.layers) do
    if layer.name == "bg" then
      map = loadBackground(map, layer)
    elseif layer.name == "bounds" then
      map = loadBounds(map, layer)
    elseif layer.name == "entrances" then
      map = loadEntrances(map, layer)
    elseif layer.name == "exits" then
      map = loadExits(map, layer)
    elseif layer.name == "poi" then
      map = loadPointsOfInterest(map, layer)
    end
  end

  return map
end

return _M
