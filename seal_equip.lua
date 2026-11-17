local vkeys = require 'vkeys'
local sampev = require 'samp.events'
local inicfg = require 'inicfg'

local isProcessing = false
local configFile = 'seal_equip.ini'

-- Настройки по умолчанию (Windows-1251)
local config = inicfg.load({
    settings = {
        equipId = "32",
        unequipId = "0",
        hatCmd = "/hat 1",
        equipMe = "надел берет спецподразделения SEAL",
        equipDo1 = "На форме отличительные знаки: Army SF || SEAL",
        equipDo2 = "В руках находится табельное оружие.",
        unequipMe = "снял берет спецподразделения SEAL",
        unequipDo = "Личночность скрыта! Опознавательных знаков нет!"
    }
}, configFile)

local function saveConfig()
    inicfg.save(config, configFile)
end

-- Функция надевания формы SEAL
local function equipSEAL()
    sampSendChat("/clist " .. config.settings.equipId)
    wait(800)
    sampSendChat(config.settings.hatCmd)
    wait(500)
    sampSendChat("/me " .. config.settings.equipMe)
    wait(500)
    sampSendChat("/do " .. config.settings.equipDo1)
    wait(500)
    sampSendChat("/do " .. config.settings.equipDo2)
end

-- Функция снятия формы
local function unequipSEAL()
    sampSendChat("/clist " .. config.settings.unequipId)
    wait(800)
    sampSendChat("/me " .. config.settings.unequipMe)
    wait(500)
    sampSendChat("/do " .. config.settings.unequipDo)
end

function main()
    while not isSampAvailable() do wait(100) end

    -- Команды для настройки прямо в игре
    sampRegisterChatCommand("seal_eqid", function(arg)
        if arg ~= "" then config.settings.equipId = arg; saveConfig(); sampAddChatMessage("[SEAL] ID клиста (надеть) изменен на "..arg, -1) end
    end)
    sampRegisterChatCommand("seal_unid", function(arg)
        if arg ~= "" then config.settings.unequipId = arg; saveConfig(); sampAddChatMessage("[SEAL] ID клиста (снять) изменен на "..arg, -1) end
    end)
    sampRegisterChatCommand("seal_hat", function(arg)
        if arg ~= "" then config.settings.hatCmd = arg; saveConfig(); sampAddChatMessage("[SEAL] Команда берета изменена", -1) end
    end)
    sampRegisterChatCommand("seal_eqme", function(arg)
        if arg ~= "" then config.settings.equipMe = arg; saveConfig(); sampAddChatMessage("[SEAL] /me (надевание) изменено", -1) end
    end)
    sampRegisterChatCommand("seal_eqdo1", function(arg)
        if arg ~= "" then config.settings.equipDo1 = arg; saveConfig(); sampAddChatMessage("[SEAL] /do 1 (надевание) изменено", -1) end
    end)
    sampRegisterChatCommand("seal_eqdo2", function(arg)
        if arg ~= "" then config.settings.equipDo2 = arg; saveConfig(); sampAddChatMessage("[SEAL] /do 2 (надевание) изменено", -1) end
    end)
    sampRegisterChatCommand("seal_unme", function(arg)
        if arg ~= "" then config.settings.unequipMe = arg; saveConfig(); sampAddChatMessage("[SEAL] /me (снятие) изменено", -1) end
    end)
    sampRegisterChatCommand("seal_undo", function(arg)
        if arg ~= "" then config.settings.unequipDo = arg; saveConfig(); sampAddChatMessage("[SEAL] /do (снятие) изменено", -1) end
    end)

    sampAddChatMessage("[SEAL]: Скрипт формы загружен.", -1)
    sampAddChatMessage("[SEAL]: Настройка через команды: /seal_eqid, /seal_eqme, /seal_eqdo1 и т.д.", -1)

    while true do
        wait(0)

        -- Бинд на НАДЕВАНИЕ формы (X + 4)
        if isKeyDown(vkeys.VK_X) and isKeyJustPressed(vkeys.VK_4) then
            lua_thread.create(function() equipSEAL() end)
        end

        -- Бинд на СНЯТИЕ формы (X + 3)
        if isKeyDown(vkeys.VK_X) and isKeyJustPressed(vkeys.VK_3) then
            lua_thread.create(function() unequipSEAL() end)
        end
    end
end

-- Перехват ручного ввода команд в чат
function sampev.onSendChat(text)
    if isProcessing then return end

    local cleanText = text:gsub("^%s+", ""):gsub("%s+$", "")
    
    if cleanText == "/clist " .. config.settings.equipId then
        isProcessing = true
        lua_thread.create(function()
            equipSEAL()
            wait(1000)
            isProcessing = false
        end)
        return false
    end

    if cleanText == "/clist " .. config.settings.unequipId then
        isProcessing = true
        lua_thread.create(function()
            unequipSEAL()
            wait(1000)
            isProcessing = false
        end)
        return false
    end
end
