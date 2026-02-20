local lg = love.graphics
local assets = require("assets")
local scenes = require("lib.scenes")
local camera = require("lib.camera")
local Inky = require("vendor.inky")
local Button = require("lib.button")
local v = require("lib.vector")

local menu

menu = {
  options = {
    {
      name = "Resume",
      cb = function()
        if menu.gameStarted then
          BUS:publish("game_started")
        end
        scenes:pop()
      end,
    },
    {
      name = "Restart Level",
      cb = function()
        scenes.switch("game", menu.level)
      end,
    },
    {
      name = "Start Over",
      cb = function()
        scenes.switch("game", "level0")
      end,
    },
    {
      name = "Exit",
      cb = function()
        love.event.quit()
      end,
    },
  },
}

function menu:init(level, gameStarted)
  self.gameStarted = gameStarted
  self.level = level
  self.scene = Inky.scene()
  self.pointer = Inky.pointer(self.scene)

  self.items = {}
  for _, entry in ipairs(self.options) do
    self.items[#self.items + 1] = Button(self.scene, entry.name, assets.fonts.standard, entry.cb)
  end

  self.camera = camera:new()

  menu.mouseListener = BUS:subscribe("mouseclicked_primary", function()
    self.pointer:raise("release")
  end)
end

function menu:update()
  local mx, my = love.mouse.getX(), love.mouse.getY()
  local lx, ly = self.camera:worldCoords(mx, my)
  self.pointer:setPosition(lx, ly)
end

function menu:draw()
  self.camera:attach()

  lg.setColor(0, 0, 0, 0.8)

  lg.rectangle("fill", 0, 0, GAME_WIDTH, GAME_HEIGHT)

  lg.setColor(1, 1, 1, 1)

  lg.printf("OPTIONS", assets.fonts.standard, 0, 20, GAME_WIDTH, "center")

  local startPosition = v(
    GAME_WIDTH / 2 - BUTTON_WIDTH / 2,
    GAME_HEIGHT / 2 - (BUTTON_HEIGHT + BUTTON_MARGIN) * #self.options / 2
  )

  self.scene:beginFrame()
  for idx, button in ipairs(self.items) do
    button.props.margin = BUTTON_MARGIN
    local position = startPosition + v(0, (idx - 1) * (BUTTON_HEIGHT + BUTTON_MARGIN))
    button:render(position.x, position.y, BUTTON_WIDTH, BUTTON_HEIGHT)
  end
  self.scene:finishFrame()

  self.camera:detach()
end

function menu:close()
  BUS:unsubscribe(self.mouseListener)
end

return menu
