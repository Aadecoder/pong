-- Ball Class defining the ball

Ball = Class {}

-- The constructor function
function Ball:init(x, y, width, height)
  self.x = x
  self.y = y
  self.width = width
  self.height = height

  self.dy = 0
  self.dx = 0
end

-- A booolean function that checks if the ball collided with the paddle
function Ball:collides(paddle)
  if self.x >= paddle.x + paddle.width or paddle.x >= self.x + self.width then
    return false
  end

  if self.y >= paddle.y + paddle.height or paddle.y >= self.y + self.height then
    return false
  end

  return true
end

-- Resets the position of the ball
function Ball:reset()
  self.x = VIRTUAL_WIDTH / 2 - 2
  self.y = VIRTUAL_HEIGHT / 2 - 2
  self.width = 4
  self.height = 4
end

-- updates the speed of the ball
function Ball:update(dt, paddle)
  self.x = self.x + self.dx * dt
  self.y = self.y + self.dy * dt
end

-- renders the ball
function Ball:render()
  love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
end
