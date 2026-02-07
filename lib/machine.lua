--[[
  Bare-bones state machine with ability to pass context, like pubsub? 
]]

Machine = {}

-- state phases: enter, update, exit, draw
-- return value - next state name or nil
-- transition possible on: enter, update
-- public API: build, reset, setState, update, draw

function Machine:build(states, startState)
  local machine = {
    context = {},
    states = states or {},
    currentState = nil,
    startState = startState,
  }

  self.__index = self
  return setmetatable(machine, self)
end

function Machine:reset()
  self:setState(self.startState, true)
end

function Machine:addState(state, tbl)
  self.states[state] = tbl
end

function Machine:setState(state, force)
  if (self.states[state] and self.currentState ~= state) or force then
    if self.currentState then
      self:_exit()
    end
    self.context = {}
    self.currentState = state
    self:_enter()
  end
end

function Machine:update(dt)
  local update = self.states[self.currentState].update

  if update then
    local newState = update(self.context, dt)

    if newState then
      self:setState(newState)
    end
  end
end

function Machine:draw()
  local draw = self.states[self.currentState].draw

  if draw then
    draw(self.context)
  end
end

function Machine:_enter()
  local enter = self.states[self.currentState].enter

  if enter then
    local newState = enter(self.context)

    if newState then
      self:setState(newState)
    end
  end
end

function Machine:_exit()
  local exit = self.states[self.currentState].exit

  if exit then
    exit(self.context)
  end
end

return Machine
