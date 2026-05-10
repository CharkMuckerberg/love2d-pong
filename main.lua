local fonts = {}

function love.load()
    fonts.small = love.graphics.newFont("assets/fonts/VT323-Regular.ttf", 36)
    fonts.large = love.graphics.newFont("assets/fonts/VT323-Regular.ttf", 72)
    bounceSound = love.audio.newSource("assets/sounds/paddle_impact.ogg", "static")
    love.graphics.setBackgroundColor(0.6549019607843137, 0.592156862745098, 0.4588235294117647)
    MOVEMENT = 6
    WINDOW_WIDTH = love.graphics.getWidth()
    WINDOW_HEIGHT = love.graphics.getHeight()
    PADDLE_WIDTH = 10
    PADDLE_HEIGHT = 100
    STARTING_PADDLE_Y = WINDOW_HEIGHT / 2 - PADDLE_WIDTH / 2
    INITIAL_BALL_SPEED = 4
    PLAYER_1_SCORE = 0
    PLAYER_2_SCORE = 0
    SPEED_INCREASE = 1
    PAUSED = true
    paddle_1 = { x = 0, y = STARTING_PADDLE_Y, width = PADDLE_WIDTH, height = PADDLE_HEIGHT }
    paddle_2 = { x = WINDOW_WIDTH - PADDLE_WIDTH, y = STARTING_PADDLE_Y, width = PADDLE_WIDTH, height = PADDLE_HEIGHT }
    initial_ball_x, initial_ball_y = get_initial_ball_position_and_velocity()
    ball = { x = initial_ball_x, y = initial_ball_y, radius = 5, dx = -1 * INITIAL_BALL_SPEED, dy = 0 }
end

function smallPrint(text, x, y)
    love.graphics.setFont(fonts.small)
    love.graphics.print(text, x, y)
end

function largePrint(text, x, y)
    love.graphics.setFont(fonts.large)
    love.graphics.print(text, x, y)
end

function playBounceSound()
    -- call stop sound before playing sound to handle case where the sound
    -- is already playing
    bounceSound:stop()
    bounceSound:play()
end

function love.update()
    -- Handle user input
    if PAUSED then
        if love.keyboard.isDown("space") then
            PAUSED = false
        end
        return
    end
    user_1_direction = get_user_input(1)
    user_2_direction = get_user_input(2)
    if user_1_direction == "up" then
        paddle_1.y = paddle_1.y - MOVEMENT
    end
    if user_1_direction == "down" then
        paddle_1.y = paddle_1.y + MOVEMENT
    end
    if user_2_direction == "up" then
        paddle_2.y = paddle_2.y - MOVEMENT
    end
    if user_2_direction == "down" then
        paddle_2.y = paddle_2.y + MOVEMENT
    end

    -- Ensure paddles stay in bounds
    paddle_1.y = clamp(paddle_1.y, 0, WINDOW_HEIGHT - PADDLE_HEIGHT)
    paddle_2.y = clamp(paddle_2.y, 0, WINDOW_HEIGHT - PADDLE_HEIGHT)
    -- update ball position
    ball.x = ball.x + ball.dx
    ball.y = ball.y + ball.dy

    -- handle collisions with paddles
    if ball.x < paddle_1.x + paddle_1.width and ball.y - ball.radius >= paddle_1.y and ball.y <= paddle_1.y + paddle_1.height then
        playBounceSound()
        ball.dx = ball.dx * -1
        if ball.dx < 0 then
            ball.dx = ball.dx - SPEED_INCREASE
        else
            ball.dx = ball.dx + SPEED_INCREASE
        end
        ball.dy = get_new_ball_velocity(ball, paddle_1)
        print(ball.dx)
    end

    if ball.x > paddle_2.x and ball.y - ball.radius >= paddle_2.y and ball.y <= paddle_2.y + paddle_2.height then
        playBounceSound()
        ball.dx = ball.dx * -1
        if ball.dx < 0 then
            ball.dx = ball.dx - SPEED_INCREASE
        else
            ball.dx = ball.dx + SPEED_INCREASE
        end
        print(ball.dx)
        ball.dy = get_new_ball_velocity(ball, paddle_2)
    end

    -- handle collisions with walls
    if ball.y <= 0 then
        ball.dy = ball.dy * -1

        playBounceSound()
    end

    if ball.y + ball.radius * 2 >= WINDOW_HEIGHT then
        playBounceSound()
        ball.dy = ball.dy * -1
    end

    if ball.x < 0 then
        PLAYER_2_SCORE = PLAYER_2_SCORE + 1
        ball.x, ball.y, ball.dx, ball.dy = get_initial_ball_position_and_velocity()
        PAUSED = true
        paddle_1.y = STARTING_PADDLE_Y
        paddle_2.y = STARTING_PADDLE_Y
    end

    if ball.x > WINDOW_WIDTH then
        PLAYER_1_SCORE = PLAYER_1_SCORE + 1
        ball.x, ball.y, ball.dx, ball.dy = get_initial_ball_position_and_velocity()
        PAUSED = true
        paddle_1.y = STARTING_PADDLE_Y
        paddle_2.y = STARTING_PADDLE_Y
    end
end

function love.draw()
    -- Draw paddles
    love.graphics.setColor(0.8235294117647058, 0.6745098039215687, 0.1803921568627451)
    love.graphics.rectangle("fill", paddle_1.x, paddle_1.y, paddle_1.width, paddle_1.height)
    love.graphics.setColor(0.1568627450980392, 0.19215686274509805, 0.6745098039215687)
    love.graphics.rectangle("fill", paddle_2.x, paddle_2.y, paddle_2.width, paddle_2.height)
    love.graphics.setColor(0.8627450980392157, 0.8313725490196079, 0.792156862745098)
    largePrint(tostring(PLAYER_1_SCORE), 100, 100)
    largePrint(tostring(PLAYER_2_SCORE), WINDOW_WIDTH - 100, 100)


    if PAUSED then
        smallPrint("Press Space to Start", WINDOW_WIDTH / 2 - 140, 200)
    end

    love.graphics.setColor(0.17647058823529413, 0.16470588235294117, 0.17647058823529413)
    love.graphics.circle("fill", ball.x, ball.y, ball.radius)
end

function get_user_input(player)
    if player == 1 then
        if love.keyboard.isDown("s") then
            return "down"
        end
        if love.keyboard.isDown("w") then
            return "up"
        end
    end
    if player == 2 then
        if love.keyboard.isDown("down") then
            return "down"
        end
        if love.keyboard.isDown("up") then
            return "up"
        end
    end
end

function clamp(val, min, max)
    if val < min then
        return min
    end
    if val > max then
        return max
    end
    return val
end

function get_new_ball_velocity(ball, paddle)
    local center_of_ball = ball.y + ball.radius
    local center_of_paddle = paddle.y + paddle.height / 2
    local collision_multiplier = -1 * (center_of_paddle - center_of_ball) / (PADDLE_HEIGHT / 2)
    if abs(collision_multiplier) < 0.2 then
        return 0
    end
    return INITIAL_BALL_SPEED * collision_multiplier
end

function get_initial_ball_position_and_velocity()
    local x = WINDOW_WIDTH / 2
    local y = WINDOW_HEIGHT / 2
    local dx = -1 * INITIAL_BALL_SPEED
    local dy = 0
    return x, y, dx, dy
end

function abs(n)
    if n < 0 then
        return n * -1
    end
    return n
end
