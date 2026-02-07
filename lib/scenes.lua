-- Adapted from https://love2d.org/forums/viewtopic.php?t=92877

local scenes = {}

local loaded = {}
local focus = {}

function scenes.init(scenesPath, startScene)
  for _, v in ipairs(love.filesystem.getDirectoryItems(scenesPath)) do
    if string.find(v, ".lua") then
      local modulePath = string.gsub(scenesPath, "/", ".") .. string.gsub(v, ".lua", "")
      loaded[string.gsub(v, ".lua", "")] = require(modulePath)
    end
  end

  if startScene then
    scenes.push(startScene)
  end
end

function scenes.push(scene, ...)
  loaded[scene]:init(...)
  focus[#focus + 1] = scene
end

function scenes.pop()
  local currentFocus = scenes.currentFocus()
  if #focus > 1 then
    if loaded[currentFocus].close then
      loaded[currentFocus]:close()
    end
    focus[#focus] = nil
  end
end

function scenes.switch(scene, ...)
  for idx = #focus, 1, -1 do
    if loaded[focus[idx]].close then
      loaded[focus[idx]]:close()
    end
  end
  focus = {}
  scenes.push(scene, ...)
end

function scenes.currentFocus()
  return focus[#focus]
end

function scenes.update(dt)
  if loaded[scenes.currentFocus()].update then
    loaded[scenes.currentFocus()]:update(dt)
  end
end

function scenes.draw()
  for _, v in ipairs(focus) do
    loaded[v]:draw()
  end
end

return scenes
