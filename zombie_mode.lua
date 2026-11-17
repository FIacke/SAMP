script_name("Zombie Mode")
script_author("OpenAI")

local encoding = require 'encoding'
local vkeys = require 'vkeys'
encoding.default = 'CP1251'
local u8 = encoding.UTF8

local isDoubleJumpEnabled = false

local function sendChat(text)
    sampAddChatMessage(u8:decode(text), -1)
end

local function processJump()
    if not isDoubleJumpEnabled then return end
    local ped = PLAYER_PED
    
    -- Если мы в воздухе и нажимаем ПРОБЕЛ (или другую клавишу)
    if isKeyJustPressed(vkeys.VK_SPACE) and not isCharOnGround(ped) then
        local vx, vy, vz = getCharVelocity(ped)
        setCharVelocity(ped, vx, vy, vz + 0.15) -- Импульс вверх
        taskPlayAnimNonInterruptable(ped, "PED", "JUMP_LAUNCH", 4.0, 0, 0, 0, 0)
        sendChat("{2B87C8}[Zombie]: Двойной прыжок!")
    end
end

function main()
    while not isSampAvailable() do wait(100) end
    
    -- Регистрируем команду
    sampRegisterChatCommand("zombie", function()
        isDoubleJumpEnabled = not isDoubleJumpEnabled
        if isDoubleJumpEnabled then
            sendChat("{2B87C8}[Zombie]: Режим ВКЛЮЧЕН. Прыгайте!")
        else
            sendChat("{2B87C8}[Zombie]: Режим ВЫКЛЮЧЕН.")
        end
    end)
    
    sendChat("{2B87C8}[Zombie]: Скрипт загружен. Введите /zombie для вкл/выкл.")
    
    while true do
        wait(0)
        processJump()
    end
end
