script_name("Zombie Mode")
script_author("OpenAI (Recreated from 4NCE)")
script_description("Double Jump & Zombie Mode with ImGui menu")

local imgui = require 'mimgui'
local new = imgui.new
local encoding = require 'encoding'
local inicfg = require 'inicfg'
local vkeys = require 'vkeys'

encoding.default = 'CP1251'
local u8 = encoding.UTF8

local configFile = 'zombiemode.ini'
local config = inicfg.load({
    settings = {
        enable = true,
        keyjump = vkeys.VK_LSHIFT -- По умолчанию Shift
    }
}, configFile)

local active = false
local isJumping = false
local jumpTimer = 0

local function saveConfig()
    inicfg.save(config, configFile)
end

local function sendChat(text)
    sampAddChatMessage(u8:decode(text), -1)
end

-- Основная логика двойного прыжка
local function processJump()
    if not config.settings.enable then return end

    local ped = PLAYER_PED
    local x, y, z = getCharCoordinates(ped)
    local vx, vy, vz = getCharVelocity(ped)

    -- Если игрок в воздухе и нажимает клавишу прыжка
    if isKeyDown(config.settings.keyjump) and isKeyJustPressed(config.settings.keyjump) then
        if not isCharOnGround(ped) and not isJumping then
            -- Применяем импульс вверх для двойного прыжка
            setCharVelocity(ped, vx, vy, vz + 0.15)
            taskPlayAnimNonInterruptable(ped, "PED", "JUMP_LAUNCH", 4.0, 0, 0, 0, 0)
            isJumping = true
            jumpTimer = os.clock() + 1.0 -- Кулдаун 1 секунда, чтобы не улететь в космос
        end
    end

    -- Сброс кулдауна при приземлении
    if isCharOnGround(ped) then
        isJumping = false
    end
    
    if isJumping and os.clock() > jumpTimer then
        isJumping = false
    end
end

-- Отрисовка меню ImGui
local renderWindow = new.bool(false)

local function renderMenu()
    if renderWindow[0] then
        imgui.Begin("Zombie Mode Menu", renderWindow)
        
        imgui.Text("Настройки DoubleJump:")
        imgui.Separator()
        
        if imgui.Checkbox("Включить DoubleJump", new.bool(config.settings.enable)) then
            config.settings.enable = not config.settings.enable
            saveConfig()
            sendChat("{2B87C8}[Zombie Mode]{FFFFFF} DoubleJump: " .. (config.settings.enable and "ВКЛ" or "ВЫКЛ"))
        end
        
        imgui.Spacing()
        
        imgui.Text("Клавиша для прыжка:")
        if imgui.Button("Сменить клавишу (Сейчас: " .. getKeysName(config.settings.keyjump) .. ")") then
            -- Встроенный хоткей mimgui для смены клавиши
            imgui.OpenPopup("Смена клавиши")
        end
        
        if imgui.BeginPopupModal("Смена клавиши", nil, imgui.WindowFlags.AlwaysAutoResize) then
            imgui.Text("Нажмите любую клавишу для смены...")
            
            -- Проверяем нажатие клавиш
            for i = 1, 255 do
                if isKeyJustPressed(i) then
                    config.settings.keyjump = i
                    saveConfig()
                    sendChat("{2B87C8}[Zombie Mode]{FFFFFF} Клавиша изменена на: " .. getKeysName(i))
                    imgui.CloseCurrentPopup()
                    break
                end
            end
            
            if imgui.Button("Отмена") then
                imgui.CloseCurrentPopup()
            end
            imgui.EndPopup()
        end
        
        imgui.Separator()
        if imgui.Button("Закрыть меню") then
            renderWindow[0] = false
        end
        
        imgui.End()
    end
end

-- Хук отрисовки ImGui
function imgui.OnDrawFrame()
    processJump()
    renderMenu()
end

function main()
    while not isSampAvailable() do wait(100) end

    -- Регистрация команды для открытия меню
    sampRegisterChatCommand("zombie", function()
        renderWindow[0] = not renderWindow[0]
        if renderWindow[0] then
            sampAddChatMessage("{2B87C8}[Zombie Mode]{FFFFFF}: Меню открыто.", -1)
        end
    end)

    sendChat("{2B87C8}[Zombie Mode]{FFFFFF}: Скрипт загружен. Используйте /zombie для открытия меню.")
    sendChat("{2B87C8}[Zombie Mode]{FFFFFF}: Текущая клавиша прыжка: " .. getKeysName(config.settings.keyjump))

    while true do
        wait(0)
        -- Вся логика прыжка теперь внутри imgui.OnDrawFrame
    end
end
