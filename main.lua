push = require 'push'
Class = require 'class'
require 'Ball'
require 'Paddle'

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

PADDLE_SPEED = 200

function love.load()
  love.graphics.setDefaultFilter('nearest', 'nearest')

  love.window.setTitle("Pong")

  math.randomseed(os.time())

  smallFont = love.graphics.newFont('font.ttf', 8)
  largeFont = love.graphics.newFont('font.ttf', 16)
  scoreFont = love.graphics.newFont('font.ttf', 32)
  titleFont = love.graphics.newFont('font.ttf', 64)
  love.graphics.setFont(smallFont)

  sounds = {
    ['paddle_hit'] = love.audio.newSource('sounds/paddle_hit.wav', 'static'),
    ['score'] = love.audio.newSource('sounds/score.wav', 'static'),
    ['wall_hit'] = love.audio.newSource('sounds/wall_hit.wav', 'static'),
    ['pingpong'] = love.audio.newSource('sounds/pingpong.mp3', 'static')
  }

  sounds['pingpong']:setLooping(true)
  sounds['pingpong']:play()

  love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT, {
    resizable = false,
    vsync = true,
    fullscreen = false
  })

  push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT,
    { fullscreen = false, resizable = false, vsync = true })

  player1 = Paddle(10, VIRTUAL_HEIGHT / 2 - 10, 5, 20)
  player2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT / 2 - 10, 5, 20)

  ball = Ball(VIRTUAL_WIDTH / 2 - 2, VIRTUAL_HEIGHT / 2 - 2, 4, 4)

  player1score = 0
  player2score = 0

  servingPlayer = 1

  winningPlayer = 0

  -- 1. multiplayer
  -- 2. singleplayer
  game_mode = 'singleplayer'

  -- 1. 'start' : the beginning of the game before any serve
  -- 2. 'serve' : waiting on the key press to serve a ball
  -- 3. 'play' : the ball is in play and is bounced between the paddles
  -- 4. 'done' : the game is over with one winner and now the game could be restarted
  game_state = 'start'
end

function love.resize(w, h)
  push:resize(w, h)
end

function love.update(dt)
  if game_state == 'serve' then
    ball.dy = math.random(-50, 50)
    if servingPlayer == 1 then
      ball.dx = -math.random(140, 200)
    else
      ball.dx = math.random(140, 200)
    end
  elseif game_state == 'play' then
    -- if the ball collides with the player1 (on the left)
    if ball:collides(player1) then
      ball.dx = -(ball.dx - 0.1 * math.abs(player1.dy))
      ball.dy = 0.5 * player1.dy
      ball.x = player1.x + 5

      sounds['paddle_hit']:play()
    end

    -- if the ball collides with the player2 (on the right)
    if ball:collides(player2) then
      ball.dx = -(ball.dx + 0.1 * math.abs(player2.dy))
      ball.x = player2.x - 4

      if game_mode == 'singleplayer' then
        if ball.dy < 0 then
          ball.dy = -math.random(10, 150)
        else
          ball.dy = math.random(10, 150)
        end
      else
        ball.dy = 0.5 * player2.dy
      end

      sounds['paddle_hit']:play()
    end

    -- if the ball collides with the top wall
    if ball.y <= 0 then
      ball.y = 0
      ball.dy = -ball.dy
      sounds['wall_hit']:play()
    end

    -- if the ball collides with the bottom wall
    if ball.y >= VIRTUAL_HEIGHT - 4 then
      ball.y = VIRTUAL_HEIGHT - 4
      ball.dy = -ball.dy
      sounds['wall_hit']:play()
    end

    -- if the player2 won
    if ball.x <= 0 then
      servingPlayer = 1
      player2score = player2score + 1
      sounds['score']:play()

      if player2score == 10 then
        winningPlayer = 2
        game_state = 'done'
      else
        game_state = 'serve'
        ball:reset()
        player1:reset()
        player2:reset()
      end
    end

    -- if player1 won
    if ball.x > VIRTUAL_WIDTH then
      servingPlayer = 2
      player1score = player1score + 1
      sounds['score']:play()

      if player1score == 10 then
        winningPlayer = 1
        game_state = 'done'
      else
        game_state = 'serve'
        ball:reset()
        player1:reset()
        player2:reset()
      end
    end
  end

  -- moving the paddles
  -- player1
  if love.keyboard.isDown('w') then
    player1.dy = -PADDLE_SPEED
  elseif love.keyboard.isDown('s') then
    player1.dy = PADDLE_SPEED
  else
    player1.dy = 0
  end

  if game_mode == 'multiplayer' then
    -- player2
    if love.keyboard.isDown('up') then
      player2.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('down') then
      player2.dy = PADDLE_SPEED
    else
      player2.dy = 0
    end
  end

  if game_mode == 'singleplayer' then
    -- player2:reach(ball.y)

    -- 1. Reaction Threshold: Only move if the ball is past the middle of the screen
    -- This gives the player a chance to "out-angle" the AI.
    if ball.x > VIRTUAL_WIDTH / 2 then
      -- 2. Add a "Buffer": The AI only moves if the ball is significantly
      -- above or below the center of the paddle.
      local paddleCenter = player2.y + (player2.height / 2)
      -- Increasing this number (e.g., to 10 or 15) makes the AI "lazier"
      local errorMargin = math.random(8, 12)

      if ball.y > paddleCenter + errorMargin then
        player2.dy = PADDLE_SPEED * 0.8 -- AI moves slightly slower than player
      elseif ball.y < paddleCenter - errorMargin then
        player2.dy = -PADDLE_SPEED * 0.8
      else
        player2.dy = 0
      end
    else
      -- 3. Idle: If the ball is on the player's side, the AI stays still
      player2.dy = 0
    end
  end

  if game_state == 'play' then
    ball:update(dt)
  end

  player1:update(dt)
  player2:update(dt)
end

-- handle key presses
function love.keypressed(key)
  if key == 'escape' then
    love.event.quit()
  elseif key == 'return' or key == 'enter' then
    if game_state == 'start' then
      game_state = 'serve'
    elseif game_state == 'serve' then
      game_state = 'play'
    elseif game_state == 'done' then
      game_state = 'serve'

      ball:reset()
      player1:reset()
      player2:reset()

      player1score = 0
      player2score = 0

      if winningPlayer == 1 then
        servingPlayer = 2
      else
        servingPlayer = 1
      end
    end
  end

  if key == 'm' then
    if game_state == 'start' or game_state == 'done' then
      if game_mode == 'singleplayer' then
        game_mode = 'multiplayer'
      else
        game_mode = 'singleplayer'
      end
    end
  end
end

function love.draw()
  push:start()

  love.graphics.clear(40 / 255, 45 / 255, 52 / 255, 1)

  if game_state == 'start' or game_state == 'done' then
    -- Display current mode
    love.graphics.setFont(smallFont)
    love.graphics.print('Mode: ', 300, 10)
    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.print(game_mode, 330, 10)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print('Press "M" to change mode', 300, 20)
  end

  if game_state == 'start' then
    love.graphics.setFont(largeFont)
    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.printf('Welcome to Pong!', 0, VIRTUAL_HEIGHT / 2 - 20, VIRTUAL_WIDTH, 'center')
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(smallFont)
    love.graphics.printf('Press Enter to begin', 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, 'center')
  elseif game_state == 'serve' then
    love.graphics.setFont(smallFont)
    love.graphics.printf('Player ' .. tostring(servingPlayer) .. "'s serve!", 0, 10, VIRTUAL_WIDTH, 'center')
  elseif game_state == 'play' then

  elseif game_state == 'done' then
    love.graphics.setFont(largeFont)
    love.graphics.printf('Player ' .. tostring(winningPlayer) .. " wins!", 0, VIRTUAL_HEIGHT / 2 - 20, VIRTUAL_WIDTH,
      'center')
    love.graphics.setFont(smallFont)
    love.graphics.printf('Press Enter to restart!', 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, 'center')
  end

  if game_state == 'serve' or game_state == 'play' then
    displayScore()
    player1:render()
    player2:render()
    ball:render()
  end

  displayFPS()

  push:finish()
end

function displayScore()
  love.graphics.setFont(scoreFont)
  love.graphics.print(tostring(player1score), VIRTUAL_WIDTH / 2 - 50, VIRTUAL_HEIGHT / 3)
  love.graphics.print(tostring(player2score), VIRTUAL_WIDTH / 2 + 30, VIRTUAL_HEIGHT / 3)
end

function displayFPS()
  love.graphics.setFont(smallFont)
  love.graphics.setColor(0, 1, 0, 1)
  love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 10, 10)
  love.graphics.setColor(1, 1, 1, 1)
end
