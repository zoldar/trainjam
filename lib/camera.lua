local humpCamera = require("vendor.camera")
local screen = require("lib.screen")

local camera = {}

function camera:new(bounds)
  local state = {}

  if bounds then
    camera.bounds = {}
    camera.bounds.xMin = bounds.x + GAME_WIDTH / 2
    camera.bounds.yMin = bounds.x + GAME_HEIGHT / 2
    camera.bounds.xMax = bounds.x + bounds.width - GAME_WIDTH / 2
    camera.bounds.yMax = bounds.y + bounds.height - GAME_HEIGHT / 2
  end

  state.hump = humpCamera(GAME_WIDTH / 2, GAME_HEIGHT / 2, screen.scale)

  self.__index = self
  return setmetatable(state, self)
end

function camera:lookAt(obj)
  local x = obj.position and obj.position.x or obj.x
  local y = obj.position and obj.position.y or obj.y
  local xOffset = obj.width / 2 or 0
  local yOffset = obj.height / 2 or 0
  local cx, cy = x + xOffset, y + yOffset

  if self.bounds then
    cx = math.max(math.min(cx, self.bounds.xMax), self.bounds.xMin)
    cy = math.max(math.min(cy, self.bounds.yMax), self.bounds.yMin)
  end

  self.hump:lookAt(cx, cy)
end

function camera:attach()
  self.hump:attach()
end

function camera:detach()
  self.hump:detach()
end

function camera:worldCoords(x, y)
  return self.hump:worldCoords(x, y)
end

return camera
