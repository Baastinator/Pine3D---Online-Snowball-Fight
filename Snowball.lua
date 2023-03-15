local Pine3d = require"Pine3D"

local speed = 15
local turnSpeed = 120

local ThreeDFrame = Pine3d.newFrame()

local mon

local levelGrid = {}

local playerHeight = 4.5
local playerWidth = 0.2

local camera = {
    x = 20,
    y = 8,
    z = 30,
    rotX = 0,
    rotY = 90,
    rotZ = -10,
    velY = 0,
}

ThreeDFrame:setCamera(camera)
ThreeDFrame:setFoV(100)

local objects = {
    ThreeDFrame:newObject(
        Pine3d.models:icosphere({res=2, color=colors.white, bottom=colors.gray}),
        20, 5, 20
    )
}

local objectRefs = {
}

local function mPrint(str)
    mon.write(str)
    local w, h = mon.getCursorPos()
    local x, y = mon.getSize()
    if (h > y) then 
        mon.clear()
        h = 0
        mon.write(str)

    end    
    mon.setCursorPos(1, h+1)
end

local function getWorldPosition()
    return (
        math.floor(camera.x / 3) - 1
    ), (
        math.floor(camera.z / 3) - 1
    )
end

math.sign = function (input)
    return input >= 0 and 1 or -1
end

local keysDown = {}
local function keyInput() 
    while true do 
---@diagnostic disable-next-line: undefined-field
        local event, key, x, y = os.pullEvent()

        if event == "key" then
            keysDown[key] = true
            if key == keys.b then
                local x ,z = getWorldPosition()
                mPrint(x..", "..z)
            end
        elseif event == "key_up" then
            keysDown[key] = nil
        end
    end
end

local function loadLevel(name) 
    for i = 0, 10+math.floor(10*(math.random())) do
        table.insert(objects, ThreeDFrame:newObject('models/cloud.p3d', 50000*(2*math.random()-1), 1000*(5*math.random()+10), 50000*(2*math.random()-1), nil, 2*math.pi*math.random()))
    end

    table.insert(objects, ThreeDFrame:newObject('models/sun.p3d', -100000, 100000, 200000, 1.2*math.pi))

    local level = paintutils.loadImage("/levels/"..name)
    local function loadObject(name, x, y, z)
        return ThreeDFrame:newObject('models/'..name..'.p3d', 3*x, y, 3*z)
    end
    for z, row in ipairs(level) do
        levelGrid[z] = {}
        for x, value in ipairs(row) do
            if value == 0 then
                table.insert(objects, loadObject('floor', x, 0, z))
                table.insert(levelGrid[z], 0)
            elseif value == 1 then
                table.insert(objects, loadObject('wallx', x, 0, z))
                table.insert(objects, loadObject('roof', x, 0, z))
                table.insert(levelGrid[z], 1)
            elseif value == 2 then
                table.insert(objects, loadObject('wallz', x, 0, z))
                table.insert(objects, loadObject('roof', x, 0, z))
                table.insert(levelGrid[z], 1)
            elseif value == 2^2 then
                table.insert(objects, loadObject('wallz', x, 0, z))
                table.insert(objects, loadObject('wallx', x, 0, z))
                table.insert(objects, loadObject('roof', x, 0, z))
                table.insert(levelGrid[z], 1)
            elseif value == 2^3 then
                table.insert(levelGrid[z], 0)
                table.insert(objects, loadObject('floor', x, 0, z))
                camera.x = 3*(x+1)
                camera.y = playerHeight
                camera.z = 3*(z+1)
            elseif value == 2^4 then
                table.insert(objects, loadObject('snowman', x, 0.1, z))
                table.insert(objects, loadObject('floor', x, 0, z))
                table.insert(levelGrid[z], 0)
            end
        end
    end

    for i, v in ipairs(objects) do
        table.insert(objectRefs, v)
    end
    -- local file = fs.open("/bruh", "w")
    -- file.write(textutils.serialize(level))
    -- file.close()
end


local function throwSnowball() 
    
end 

local function renderSnowball()
    ThreeDFrame.buffer:image(10,10,{{colors.red, colors.red}, {colors.red, colors.red, colors.red}})
end

local function handleCameraMovement(dt)
    local dx, dy, dz = 0, 0, 0 -- will represent the movement per second

    do -- handle arrow keys for camera rotation
        if keysDown[keys.left] then
            camera.rotY = (camera.rotY - turnSpeed * dt) % 360      
        end
        if keysDown[keys.right] then
            camera.rotY = (camera.rotY + turnSpeed * dt) % 360
        end
        if keysDown[keys.down] then
            camera.rotZ = math.max(-80, camera.rotZ - turnSpeed * dt)
        end
        if keysDown[keys.up] then
            camera.rotZ = math.min(80, camera.rotZ + turnSpeed * dt)
        end
    end

    do -- handle wasd keys for camera movement
        if keysDown[keys.w] then
            dx = speed * math.cos(math.rad(camera.rotY)) + dx
            dz = speed * math.sin(math.rad(camera.rotY)) + dz
        end
        if keysDown[keys.s] then
            dx = -speed * math.cos(math.rad(camera.rotY)) + dx
            dz = -speed * math.sin(math.rad(camera.rotY)) + dz
        end
        if keysDown[keys.a] then
            dx = speed * math.cos(math.rad(camera.rotY - 90)) + dx
            dz = speed * math.sin(math.rad(camera.rotY - 90)) + dz
        end
        if keysDown[keys.d] then
            dx = speed * math.cos(math.rad(camera.rotY + 90)) + dx
            dz = speed * math.sin(math.rad(camera.rotY + 90)) + dz
        end

        -- update the camera position by adding the offset and collision detection

        local x,z = getWorldPosition()

        if (
            levelGrid[z+1][
                math.floor((camera.x + dx * dt) / 3 + playerWidth)
            ] == 1            
        ) then
            dx = 0
        end

        camera.x = camera.x + dx * dt
        camera.z = camera.z + dz * dt
    end

    do --gravity and floor detection
        if keysDown[keys.space] and math.abs(camera.y - playerHeight) < 0.1 then
            camera.velY = 10
        end
    
        if camera.y > playerHeight then
            camera.velY = camera.velY + 2* dt * -9.81
        end
    
        camera.y = camera.y + camera.velY * dt
        
        if camera.y < playerHeight then
            camera.y = playerHeight
        end
    end
    
    ThreeDFrame:setCamera(camera)
end

-- handle game logic
local function handleGameLogic(dt)
    
    do --wall collision
        
    end
end

local function initDebugMon() 
    periphemu.create("debug", "monitor")
    mon = peripheral.wrap("debug")
    mon.clear()
    mon.setCursorPos(1,1)
end

-- handle the game logic and camera movement in steps
local function gameLoop()
    initDebugMon()
    local lastTime = os.clock()
    loadLevel('1')

    while true do
        -- compute the time passed since last step
        local currentTime = os.clock()
        local dt = currentTime - lastTime
        lastTime = currentTime

        -- run all functions that need to be run
        handleGameLogic(dt)
        handleCameraMovement(dt)

        -- use a fake event to yield the coroutine
        ---@diagnostic disable-next-line: undefined-field
        os.queueEvent("gameLoop")
        ---@diagnostic disable-next-line: undefined-field
        os.pullEventRaw("gameLoop")
    end
end

local function rendering()
    while true do
        -- load all objects onto the buffer and draw the buffer
        ThreeDFrame:drawObjects(objectRefs)
        -- renderSnowball()
        ThreeDFrame:drawBuffer()

        -- use a fake event to yield the coroutine
        ---@diagnostic disable-next-line: undefined-field
        os.queueEvent("rendering")
        ---@diagnostic disable-next-line: undefined-field
        os.pullEventRaw("rendering")
    end
end

parallel.waitForAny(keyInput, gameLoop, rendering)