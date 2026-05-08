-- Paddle class for defining paddle behaivour

Paddle = Class {}

-- Paddle Constructor function
function Paddle:init(x, y, width, height)
  self.x = x
  self.y = y
  self.width = width
  self.height = height
  self.dy = 0
end

-- a function to set the speed of paddle
function Paddle:update(dt)
  if self.dy < 0 then
    self.y = math.max(0, self.y + self.dy * dt)
  else
    self.y = math.min(VIRTUAL_HEIGHT - self.height, self.y + self.dy * dt)
  end
end

-- resets the position of paddle
function Paddle:reset()
  self.y = VIRTUAL_HEIGHT / 2 - 10
end

-- for the AI
function Paddle:reach(y)
  self.y = y
end

-- function to render the paddle
function Paddle:render()
  love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
end
