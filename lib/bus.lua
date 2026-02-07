--[[
  Very simplistic pubsub
]]

Bus = {}

function Bus:new()
  local state = {
    subscriptions = {},
  }
  self.__index = self
  return setmetatable(state, self)
end

function Bus:subscribe(event, callback)
  if not self.subscriptions[event] then
    self.subscriptions[event] = {}
  end

  self.subscriptions[event][callback] = callback

  return { event, callback }
end

function Bus:subscribeOnce(event, callback)
  if not self.subscriptions[event] then
    self.subscriptions[event] = {}
  end

  local wrapped = function(data)
    callback(data)
    self:unsubscribe(event, callback)
  end

  self.subscriptions[event][callback] = wrapped

  return { event, callback }
end

function Bus:unsubscribe(event, callback)
  if callback == nil then
    event, callback = unpack(event)
  end

  if self.subscriptions[event] then
    self.subscriptions[event][callback] = nil
  end
end

function Bus:publish(event, data)
  for _, callback in pairs(self.subscriptions[event] or {}) do
    callback(data)
  end
end

return Bus
