script_name("Zombie Mode")
script_author("OpenAI")

local encoding = require 'encoding'
local vkeys = require 'vkeys'
encoding.default = 'CP1251'
local u8 = encoding.UTF8

local isDoubleJumpEnabled = false
local hasJumpedInAir = false -- Защита от тройных прыжков

local function sendChat(text)
    sampAddChatMessage(u8:decode(text), -1)
end

local function processJump()
    if not isDoubleJumpEnabled then return end
    local ped = PLAYER_PED

    -- Если мы на земле, сбрасываем счетчик двойного прыжка
    if isCharOnGround(ped) then
        hasJumpedInAir = false
    else
        -- Если мы в воздухе и нажимаем SHIFT (или Пробел) и еще не прыгали
        local isJumpKeyPressed = isKeyJustPressed(vkeys.VK_LSHIFT) or isKeyJustPressed(vkeys.VK_RSHIFT) or isKeyJustPressed(vkeys.VK_SPACE)
        
        if isJumpKeyPressed and not hasJumpedInAir then
            local vx, vy, vz = getCharVelocity(ped)
            -- Жестко задаем скорость вверх (0.45), чтобы персонаж точно подлетел
            setCharVelocity(ped, vx, vy, 0.45) 
            
            hasJumpedInAir = true
            sendChat("{2B87C8}[Zombie]: Двойной прыжок!")
        end
    end
end

function main()
    while not isSampAvailable() do wait(100) end
    
    sampRegisterChatCommand("zombie", function()
        isDoubleJumpEnabled = not isDoubleJumpEnabled
        if isDoubleJumpEnabled then
            sendChat("{2B87C8}[Zombie]: Режим ВКЛЮЧЕН. Прыгайте и жмите SHIFT в воздухе!")
        else
            sendChat("{2B87C8}[Zombie]: Режим ВЫКЛЮЧЕН.")
        end
    end)
    
    sendChat("{2B87C8}[Zombie]: Загружен. /zombie для вкл/выкл.")
    
    while true do
        wait(0)
        processJump()
    end
end
