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

  assets.sounds = {
    explosion = love.audio.newSource("assets/explosion.wav", "static"),
    pickup = love.audio.newSource("assets/pickup.wav", "static"),
    switch = love.audio.newSource("assets/switch.wav", "static"),
    warning = love.audio.newSource("assets/warning.wav", "static"),
    blip1 = love.audio.newSource("assets/blip1.wav", "static"),
    blip2 = love.audio.newSource("assets/blip2.wav", "static"),
  }
end

return assets
