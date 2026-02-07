local keys = {}

function keys.configure(mappings)
  keys.mappings = mappings
  keys.bindings = {}

  for action, mappedKeys in pairs(mappings) do
    for _, key in ipairs(mappedKeys) do
      keys.bindings[key] = action
    end
  end
end

function keys.isDown(action)
  local isDown = false

  for _, key in ipairs(keys.mappings[action]) do
    if love.keyboard.isDown(key) then
      isDown = true
      break
    end
  end

  return isDown
end

function keys.toAction(key)
  return keys.bindings[key]
end

return keys
