local vkeys = require 'vkeys'
local sampev = require 'samp.events'
local imgui = require 'mimgui'
local new = imgui.new
local inicfg = require 'inicfg'
local encoding = require 'encoding'

encoding.default = 'CP1251'
local u8 = encoding.UTF8

local isProcessing = false
local configFile = 'seal_equip.ini'

-- Настройки по умолчанию
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

-- Переменные для меню ImGui
local showMenu = new.bool(false)
local bufEquipId = new.char[10](config.settings.equipId)
local bufUnequipId = new.char[10](config.settings.unequipId)
local bufHatCmd = new.char[64](config.settings.hatCmd)
local bufEquipMe = new.char[128](config.settings.equipMe)
local bufEquipDo1 = new.char[128](config.settings.equipDo1)
local bufEquipDo2 = new.char[128](config.settings.equipDo2)
local bufUnequipMe = new.char[128](config.settings.unequipMe)
local bufUnequipDo = new.char[128](config.settings.unequipDo)

local function updateConfig()
    config.settings.equipId = imgui.String(bufEquipId)
    config.settings.unequipId = imgui.String(bufUnequipId)
    config.settings.hatCmd = imgui.String(bufHatCmd)
    config.settings.equipMe = imgui.String(bufEquipMe)
    config.settings.equipDo1 = imgui.String(bufEquipDo1)
    config.settings.equipDo2 = imgui.String(bufEquipDo2)
    config.settings.unequipMe = imgui.String(bufUnequipMe)
    config.settings.unequipDo = imgui.String(bufUnequipDo)
    inicfg.save(config, configFile)
end

-- Функция надевания формы SEAL (ИСПРАВЛЕНО: добавлен u8:decode)
local function equipSEAL()
    sampSendChat("/clist " .. config.settings.equipId)
    wait(800)
    sampSendChat(config.settings.hatCmd)
    wait(500)
    sampSendChat(u8:decode("/me " .. config.settings.equipMe))
    wait(500)
    sampSendChat(u8:decode("/do " .. config.settings.equipDo1))
    wait(500)
    sampSendChat(u8:decode("/do " .. config.settings.equipDo2))
end

-- Функция снятия формы (ИСПРАВЛЕНО: добавлен u8:decode)
local function unequipSEAL()
    sampSendChat("/clist " .. config.settings.unequipId)
    wait(800)
    sampSendChat(u8:decode("/me " .. config.settings.unequipMe))
    wait(500)
    sampSendChat(u8:decode("/do " .. config.settings.unequipDo))
end

-- Отрисовка меню
local function renderMenu()
    if showMenu[0] then
        imgui.Begin("Настройки SEAL", showMenu)
        
        imgui.Text("Настройки команд:")
        imgui.InputText("ID клиста (Надеть)", bufEquipId)
        imgui.InputText("ID клиста (Снять)", bufUnequipId)
        imgui.InputText("Команда берета", bufHatCmd)
        imgui.Separator()
        
        imgui.Text("Тексты отыгровок (Надевание):")
        imgui.InputText("me", bufEquipMe)
        imgui.InputText("do 1", bufEquipDo1)
        imgui.InputText("do 2", bufEquipDo2)
        imgui.Separator()
        
        imgui.Text("Тексты отыгровок (Снятие):")
        imgui.InputText("me", bufUnequipMe)
        imgui.InputText("do", bufUnequipDo)
        imgui.Separator()
        
        if imgui.Button("Сохранить и применить", new.ImVec2(200, 30)) then
            updateConfig()
            sampAddChatMessage(u8:decode("{2B87C8}[SEAL]{FFFFFF}: Настройки сохранены!"), -1)
        end
        
        imgui.End()
    end
end

function imgui.OnDrawFrame()
    renderMenu()
end

function main()
    while not isSampAvailable() do wait(100) end

    sampRegisterChatCommand("seal", function()
        showMenu[0] = not showMenu[0]
    end)

    sampAddChatMessage(u8:decode("{2B87C8}[SEAL]{FFFFFF}: Скрипт формы загружен. Меню: /seal"), -1)

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
