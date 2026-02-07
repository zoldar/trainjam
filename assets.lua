local lg = love.graphics
local tiled = require("lib.tiled")
local anim8 = require("vendor.anim8")

local assets = {}

function assets.load()
  assets.fonts = {
    -- mono = lg.newFont("assets/dtm-mono.ttf", 20),
  }

  assets.levels = {
    -- level1 = { map = tiled.load("assets.level1") },
  }
end

return assets
