-- Adapted from https://love2d.org/wiki/Vectors
--

local Vector = {}
Vector.__index = Vector

function Vector.new(x, y)
  local v = { x = x or 0, y = y or 0 }
  setmetatable(v, Vector)
  return v
end

function Vector:distance(other)
  local dx = self.x - other.x
	local dy = self.y - other.y
	return math.sqrt(dx * dx + dy * dy)
end

function Vector.__add(a, b)
  return Vector.new(a.x + b.x, a.y + b.y)
end

function Vector.__sub(a, b)
  return Vector.new(a.x - b.x, a.y - b.y)
end

function Vector.__mul(a, b)
  if type(a) == "number" then
    return Vector.new(b.x * a, b.y * a)
  elseif type(b) == "number" then
    return Vector.new(a.x * b, a.y * b)
  else
    error("Can only multiply vector by scalar.")
  end
end

function Vector.__div(a, b)
  if type(b) == "number" then
    return Vector.new(a.x / b, a.y / b)
  else
    error("Invalid argument types for vector division.")
  end
end

function Vector.__eq(a, b)
  return a.x == b.x and a.y == b.y
end

function Vector.__ne(a, b)
  return not Vector.__eq(a, b)
end

function Vector.__unm(a)
  return Vector.new(-a.x, -a.y)
end

function Vector.__lt(a, b)
  return a.x < b.x and a.y < b.y
end

function Vector.__le(a, b)
  return a.x <= b.x and a.y <= b.y
end

function Vector.__tostring(v)
  return "(" .. v.x .. ", " .. v.y .. ")"
end

return Vector.new
