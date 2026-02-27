local lg = love.graphics
local tiled = require("lib.tiled")
local anim8 = require("vendor.anim8")

local assets = {}

function assets.load()
  assets.fonts = {
    standard = lg.newFont("assets/PublicPixel.ttf", 8),
    tiny = lg.newFont("assets/pixelated.ttf", 8),
    logo = lg.newFont("assets/Kenney Blocks.ttf", 56),
  }

  local buttonsSheet = lg.newImage("assets/buttons.png")

  assets.buttons = {
    switch_normal = {
      sprite = lg.newQuad(1, 1, 52, 25, buttonsSheet),
      sheet = buttonsSheet,
    },
    switch_pressed = {
      sprite = lg.newQuad(1, 29, 52, 25, buttonsSheet),
      sheet = buttonsSheet,
    },
    resume_normal = {
      sprite = lg.newQuad(54, 1, 52, 25, buttonsSheet),
      sheet = buttonsSheet,
    },
    resume_pressed = {
      sprite = lg.newQuad(54, 29, 52, 25, buttonsSheet),
      sheet = buttonsSheet,
    },
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
