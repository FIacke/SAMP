local vkeys = require 'vkeys'
local sampev = require 'samp.events'

local isProcessing = false -- Защита от зацикливания

-- Функция надевания формы SEAL
local function equipSEAL()
    sampSendChat("/clist 32") -- Меняем скин
    wait(800)                 -- Ждем, пока сервер применит скин
    sampSendChat("/hat 1")    -- Надеваем берет (замените на вашу команду, если нужно)
    wait(500)
    sampSendChat("/me надел берет спецподразделения SEAL")
    wait(500)
    sampSendChat("/do На форме отличительные знаки: Army SF || SEAL")
    wait(500)
    sampSendChat("/do В руках находится табельное оружие.")
end

-- Функция снятия формы
local function unequipSEAL()
    sampSendChat("/clist 0") -- Снимаем скин
    wait(800)
    sampSendChat("/me снял берет спецподразделения SEAL")
    wait(500)
    sampSendChat("/do Личночность скрыта! Опознавательных знаков нет!")
end

function main()
    while not isSampAvailable() do wait(100) end

    sampAddChatMessage("{2B87C8}[SEAL]{FFFFFF}: Скрипт формы загружен.", -1)

    while true do
        wait(0)

        -- Бинд на НАДЕВАНИЕ формы (X + 4)
        if isKeyDown(vkeys.VK_X) and isKeyJustPressed(vkeys.VK_4) then
            lua_thread.create(function()
                equipSEAL()
            end)
        end

        -- Бинд на СНЯТИЕ формы (X + 3)
        if isKeyDown(vkeys.VK_X) and isKeyJustPressed(vkeys.VK_3) then
            lua_thread.create(function()
                unequipSEAL()
            end)
        end
    end
end

-- Перехват ручного ввода команд в чат
function sampev.onSendChat(text)
    if isProcessing then return end -- Пропускаем наши автоматические команды

    if text == "/clist 32" then
        isProcessing = true
        lua_thread.create(function()
            equipSEAL()
            wait(1000)
            isProcessing = false
        end)
        return false -- Отменяем отправку изначальной команды
    end

    if text == "/clist 0" then
        isProcessing = true
        lua_thread.create(function()
            unequipSEAL()
            wait(1000)
            isProcessing = false
        end)
        return false
    end
end
