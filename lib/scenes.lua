-- Adapted from https://love2d.org/forums/viewtopic.php?t=92877
--

local Bus = require("lib.bus")

local bus = Bus:new()

local scenes = {}

local loaded = {}
local subscriptions = {}
local focus = {}

local function resetFocus(idx)
  focus[idx] = { scene = focus[idx].scene }
end

function scenes.init(scenesPath, startScene, opts)
  for _, v in ipairs(love.filesystem.getDirectoryItems(scenesPath)) do
    if string.find(v, ".lua") then
      local modulePath = string.gsub(scenesPath, "/", ".") .. string.gsub(v, ".lua", "")
      loaded[string.gsub(v, ".lua", "")] = require(modulePath)
    end
  end

  if startScene then
    scenes.push(startScene, opts)
  end
end

function scenes.subscribe(event, callback, opts)
  opts = opts or {}

  local currentFocus = scenes.currentFocus()
  if currentFocus then
    subscriptions[currentFocus] = subscriptions[currentFocus] or {}

    local subscription
    if opts.once then
      subscription = bus:subscribeOnce(event, callback)
    else
      subscription = bus:subscribe(event, callback)
    end

    table.insert(subscriptions[currentFocus], subscription)

    return subscription
  end
end

function scenes.unsubscribe(subscription)
  bus:unsubscribe(subscription)
end

function scenes.publish(event, data)
  bus:publish(event, data)
end

function scenes.push(scene, opts)
  opts = opts or {}
  local args = opts.args or {}

  focus[#focus + 1] = { scene = scene, opts = {} }

  if loaded[scene].init then
    loaded[scene]:init(unpack(args))
  end

  if opts.keepUpdate then
    focus[#focus - 1].keepUpdate = true
  end
end

function scenes.pop()
  local currentFocus = scenes.currentFocus()
  if #focus > 1 then
    if loaded[currentFocus].close then
      loaded[currentFocus]:close()
    end
    if subscriptions[currentFocus] then
      for _, subscription in ipairs(subscriptions[currentFocus]) do
        bus:unsubscribe(subscription)
      end
    end
    focus[#focus] = nil
    resetFocus(#focus)
  end
end

function scenes.switch(scene, opts)
  for idx = #focus, 1, -1 do
    if loaded[focus[idx].scene].close then
      loaded[focus[idx].scene]:close()
    end
  end
  focus = {}
  scenes.push(scene, opts)
end

function scenes.currentFocus()
  return focus[#focus].scene
end

function scenes.update(dt)
  if #focus > 1 then
    for idx = 1, #focus - 1 do
      local current = focus[idx]
      if current.keepUpdate and loaded[current.scene].update then
        loaded[current.scene]:update(dt)
      end
    end
  end

  if loaded[scenes.currentFocus()].update then
    loaded[scenes.currentFocus()]:update(dt)
  end
end

function scenes.keypressed(key)
  if loaded[scenes.currentFocus()].keypressed then
    loaded[scenes.currentFocus()]:keypressed(key)
  end
end

function scenes.keyreleased(key)
  if loaded[scenes.currentFocus()].keyreleased then
    loaded[scenes.currentFocus()]:keyreleased(key)
  end
end

function scenes.mousepressed(x, y, button)
  if loaded[scenes.currentFocus()].mousepressed then
    loaded[scenes.currentFocus()]:mousepressed(x, y, button)
  end
end

function scenes.mousereleased(x, y, button)
  if loaded[scenes.currentFocus()].mousereleased then
    loaded[scenes.currentFocus()]:mousereleased(x, y, button)
  end
end

function scenes.draw()
  for _, v in ipairs(focus) do
    loaded[v.scene]:draw()
  end
end

function scenes.resize()
  for _, scene in pairs(loaded) do
    if scene.camera then
      scene.camera:resize()
    end
  end
end

return scenes
