local v = require("lib.vector")

GAME_WIDTH, GAME_HEIGHT = 320, 240

BINDINGS = {
  use = { "space" },
  left = { "left", "a" },
  right = { "right", "d" },
  up = { "up", "w" },
  down = { "s" },
  debug = { "d" },
}

DIRECTIONS = {
  left = v(-1, 0),
  right = v(1, 0),
  up = v(0, -1),
  down = v(0, 1),
}

TILE_SIZE = 16
GRID_WIDTH = GAME_WIDTH / TILE_SIZE
GRID_HEIGHT = GAME_HEIGHT / TILE_SIZE

TRAIN_SPEED = 35

RAIL_DIRECTIONS = {
  U = { down = "up" },
  D = { up = "down" },
  L = { right = "left" },
  R = { left = "right" },
  UD = { down = "up", up = "down" },
  LR = { left = "right", right = "left" },
  RU = { right = "up", up = "right" },
  RD = { right = "down", down = "right" },
  LU = { left = "up", up = "left" },
  LD = { left = "down", down = "left" },
}

INVERSE_RAIL_2WAY = {
  up = {
    down = "UD",
    left = "LU",
    right = "RU",
  },
  down = {
    up = "UD",
    left = "LD",
    right = "RD",
  },
  left = {
    right = "LR",
    up = "LU",
    down = "LD",
  },
  right = {
    left = "LR",
    up = "RU",
    down = "RD",
  },
}

INVERSE = {
  up = "down",
  down = "up",
  left = "right",
  right = "left",
}

INVERSE[tostring(DIRECTIONS.up)] = "down"
INVERSE[tostring(DIRECTIONS.down)] = "up"
INVERSE[tostring(DIRECTIONS.left)] = "right"
INVERSE[tostring(DIRECTIONS.right)] = "left"

ORIENTATION = {
  up = "vertical",
  down = "vertical",
  left = "horizontal",
  right = "horizontal",
}

ORTHOGONAL = {
  up = DIRECTIONS.right,
  down = DIRECTIONS.right,
  left = DIRECTIONS.up,
  right = DIRECTIONS.down,
}

HITBOX_SHRINK = 3
