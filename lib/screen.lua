local screen = {}

function screen.load(gameWidth, gameHeight)
  love.graphics.setDefaultFilter("nearest", "nearest")
  screen.gameWidth, screen.gameHeight = gameWidth, gameHeight
  screen.w, screen.h = love.window.getMode()
  screen.resize(screen.w, screen.h)
end

function screen.resize(w, h)
  screen.scale = math.floor(math.min(w / screen.gameWidth, h / screen.gameHeight))
end

function screen.setSize(w, h, options)
  options = options or {}
  love.window.updateMode(w, h, options)
  screen.resize(w, h)
end

return screen
