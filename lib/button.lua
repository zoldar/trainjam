local lg = love.graphics
local Inky = require("vendor.inky")

return function(scene, label, font, action)
  return Inky.defineElement(function(self)
    self.props.hover = false
    self.props.margin = 3

    self:onPointerEnter(function()
      self.props.hover = true
    end)

    self:onPointerExit(function()
      self.props.hover = false
    end)

    self:onPointer("release", action)

    return function(_, x, y, w, h)
      lg.setColor(1, 1, 1)
      lg.rectangle("line", x, y, w, h)
      if self.props.hover then
        lg.setColor(1, 1, 0)
        lg.rectangle(
          "line",
          x - self.props.margin,
          y - self.props.margin,
          w + 2 * self.props.margin,
          h + 2 * self.props.margin
        )
      end
      lg.setColor(1, 1, 1)
      lg.printf(label, font, x, y + (h - font:getHeight()) / 2, w, "center")
    end
  end)(scene)
end
