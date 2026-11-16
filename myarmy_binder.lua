local vkeys = require 'vkeys'
local sampev = require 'samp.events'
local stocks = {}
local stockOrder = {"SF ARMY", "LV ARMY", "LS ARMY", "CARGO SHIP"}
local govWaveTime = "00:00"

local govReminderObjection = nil
local govReminderStart = nil
local govReminderObjectionDone = false
local govReminderStartDone = false

local equipmentMapping = {
    ["Desert Eagle"] = "deagle",
    ["M4A1"] = "m4",
    ["Rifle"] = "rifle",
    ["Броня"] = "armor",
    ["Взять аптечки"] = "medkit"
}

local equipConfig = {
    deagle = true,
    m4 = true,
    rifle = true,
    armor = true,
    medkit = true
}

local isEquipped = false
local lastEquipIndex = -1
local equipMarkerCoords = { x = -1, y = -1, z = -1 }

function getMyId()
    local _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
    return tostring(id or 0)
end

function processReport(text)
    text = text:gsub("id", getMyId())
    return text
end

function generateGovWaveTime()
    local t = os.date("*t")
    local hour = t.hour
    local min = t.min
    local sec = t.sec
    local remainder = min % 5
    local left = 5 - remainder

    if left <= 3 then
        min = min + left + 5
    else
        min = min + left
    end

    if min >= 60 then
        min = min - 60
        hour = (hour + 1) % 24
    end

    return string.format("%02d:%02d", hour, min)
end

function timeToMinutes(timeStr)
    local h, m = timeStr:match("(%d+):(%d+)")
    return tonumber(h) * 60 + tonumber(m)
end

function minutesToTime(total)
    total = total % 1440
    local h = math.floor(total / 60)
    local m = total % 60
    return string.format("%02d:%02d", h, m)
end

function getCurrentMinutes()
    local t = os.date("*t")
    return t.hour * 60 + t.min
end

function setupGovReminders()
    local waveMin = timeToMinutes(govWaveTime)
    govReminderObjection = minutesToTime(waveMin - 2)
    govReminderStart = govWaveTime
    govReminderObjectionDone = false
    govReminderStartDone = false
end

function checkGovReminders()
    local now = minutesToTime(getCurrentMinutes())
    if govReminderObjection and not govReminderObjectionDone and now == govReminderObjection then
        govReminderObjectionDone = true
        sampAddChatMessage("{FFFF00}[GovNews] Пора нажать второй бинд: K + P.", -1)
    end
    if govReminderStart and not govReminderStartDone and now == govReminderStart then
        govReminderStartDone = true
        sampAddChatMessage("{FFFF00}[GovNews] Время волны гос. новостей. Начинай вещать: F3 Призыв/Контракт", -1)
    end
end

function main()
    while not isSampAvailable() do wait(100) end
    sampAddChatMessage("{FF5F5F}[Binder]{ffffff}: Мой армейский биндер загружен.", -1)

    while true do
        wait(0)
        checkGovReminders()

        if isEquipped then
            local x, y, z = getCharCoordinates(PLAYER_PED)
            local dist = getDistanceBetweenCoords3d(equipMarkerCoords.x, equipMarkerCoords.y, equipMarkerCoords.z, x, y, z)
            if dist > 5 then
                isEquipped = false
                lastEquipIndex = -1
            end
        end

        if isKeyDown(vkeys.VK_J) and isKeyJustPressed(vkeys.VK_5) then
            stocks = {}
            scanStocks3d()
            sendStockReport()
        end

        if isKeyDown(vkeys.VK_J) and isKeyJustPressed(vkeys.VK_O) then
            sampSendChat("/dep OG, открыты переводы и восстановление в ряды ВМС. Выплата 10 000 000 вирт.")
        end

        if isKeyDown(vkeys.VK_J) and isKeyJustPressed(vkeys.VK_4) then
            sampSetChatInputEnabled(true)
            sampSetChatInputText(processReport("Ваша Честь, истец нарушает статью 4.4 СЗ о Судебной системе и мешает давать показания. Прошу вынести ему предупреждение."))
        end

        if isKeyDown(vkeys.VK_J) and isKeyJustPressed(vkeys.VK_P) then
            govWaveTime = generateGovWaveTime()
            setupGovReminders()
            sampSendChat(processReport("/dep OG, займу волну гос. новостей на "..govWaveTime.." возражения на п.id."))
        end

        if isKeyDown(vkeys.VK_K) and isKeyJustPressed(vkeys.VK_P) then
            sampSendChat("/dep OG, возражений не поступило. Волна гос. новостей на "..govWaveTime.." за ВМС.")
        end

        if isKeyJustPressed(vkeys.VK_HOME) then sampSendChat("/boatspawn") end
        if isKeyJustPressed(vkeys.VK_ADD) then sampSendChat("/enter") end
        if isKeyJustPressed(vkeys.VK_NEXT) then sampSendChat("/carm") end
        if isKeyJustPressed(vkeys.VK_XBUTTON2) then sampSendChat("/strobe 0") end
        if isKeyJustPressed(vkeys.VK_XBUTTON1) then sampSendChat("/strobe -1") end
        if isKeyJustPressed(vkeys.VK_SUBTRACT) then sampSendChat("/exit") end
        if isKeyJustPressed(vkeys.VK_F12) then sampSendChat("/fixcar") end
        if isKeyJustPressed(vkeys.VK_DIVIDE) then sampSendChat("/buyhouse") end

        if isKeyDown(vkeys.VK_N) and isKeyJustPressed(vkeys.VK_NUMPAD3) then sampSendChat("/healme") end
        if isKeyDown(vkeys.VK_N) and isKeyJustPressed(vkeys.VK_NUMPAD2) then sampSendChat("/grib heal") end
        if isKeyDown(vkeys.VK_N) and isKeyJustPressed(vkeys.VK_NUMPAD1) then sampSendChat("/grib eat") end

        if isKeyDown(vkeys.VK_J) and isKeyJustPressed(vkeys.VK_NUMPAD1) then sampSendChat("/r Здравия желаю, Флот! 10-8.") end
        if isKeyDown(vkeys.VK_J) and isKeyJustPressed(vkeys.VK_NUMPAD2) then sampSendChat("/r Здравия желаю!") end
        if isKeyDown(vkeys.VK_J) and isKeyJustPressed(vkeys.VK_NUMPAD3) then sampSendChat("/r Поздравляю!") end

        -- БИНДЫ НА КЛАВИШУ N
        if isKeyDown(vkeys.VK_N) and isKeyJustPressed(vkeys.VK_1) then
            sampSendChat("Здравие желаю! Мл.Мичман Лупер.")
        end
        if isKeyDown(vkeys.VK_N) and isKeyJustPressed(vkeys.VK_2) then
            sampSendChat("/do На форме отличительные знаки: Army SF || мл.мичман || SEAL || Loopere")
        end
        if isKeyDown(vkeys.VK_N) and isKeyJustPressed(vkeys.VK_4) then
            sampSendChat("Согласно конституции штата, статье 17-17.1 пункт 4, въезд на территорию строго по пропуску.")
        end
        if isKeyDown(vkeys.VK_N) and isKeyJustPressed(vkeys.VK_5) then
            sampSendChat("Предъявите пожалуйста ваши документы.")
        end
        if isKeyDown(vkeys.VK_N) and isKeyJustPressed(vkeys.VK_6) then
            sampSendChat("Всё в порядке, можете продолжать движение!")
        end
        if isKeyDown(vkeys.VK_N) and isKeyJustPressed(vkeys.VK_7) then
            sampSendChat("Я мл.Мичман Фласти Лупер SFa SEAL, здравия желаю!")
        end

        if isKeyDown(vkeys.VK_LMENU) and isKeyJustPressed(vkeys.VK_1) then sampSendChat("/lock") end
        if isKeyDown(vkeys.VK_X) and isKeyJustPressed(vkeys.VK_4) then sampSendChat("/clist 32") end
        if isKeyDown(vkeys.VK_X) and isKeyJustPressed(vkeys.VK_1) then sampSendChat("/clist 7") end
        if isKeyDown(vkeys.VK_X) and isKeyJustPressed(vkeys.VK_2) then sampSendChat("/clist 22") end
        if isKeyDown(vkeys.VK_X) and isKeyJustPressed(vkeys.VK_3) then sampSendChat("/clist 0") end
        if isKeyJustPressed(vkeys.VK_END) then sampSendChat("/time") end
    end
end

function scanStocks3d()
    for i = 0, 2048 do
        if sampIs3dTextDefined(i) then
            local text = sampGet3dTextInfoById(i)
            if text then parseStockText(text) end
        end
    end
end

function parseStockText(text)
    if not text then return end
    text = text:gsub("{......}", "")
    text = text:gsub("~.-~", "")
    text = text:gsub("\n", " ")
    text = text:gsub("%s+", " ")
    for _, name in ipairs(stockOrder) do
        local cur, max = text:match(name .. "%s+(%d+)%s*/%s*(%d+)")
        if cur and max then
            stocks[name] = { cur = tonumber(cur), max = tonumber(max) }
        end
    end
end

function sendStockReport()
    local sfa = stocks["SF ARMY"]
    local lva = stocks["LV ARMY"]
    local lsa = stocks["LS ARMY"]
    local cargo = stocks["CARGO SHIP"]

    if not sfa or not lva or not lsa or not cargo then
        local missing = {}
        if not sfa then table.insert(missing, "SF ARMY") end
        if not lva then table.insert(missing, "LV ARMY") end
        if not lsa then table.insert(missing, "LS ARMY") end
        if not cargo then table.insert(missing, "CARGO SHIP") end
        sampAddChatMessage("{FF0000}[Binder]: Не найдены склады: " .. table.concat(missing, ", "), -1)
        return
    end

    local msg = string.format("/r Склады: СФа: %d/%d, ЛВа: %d/%d, Порт ЛС: %d/%d, Сухогруз: %d/%d.",
        math.floor(sfa.cur / 1000), math.floor(sfa.max / 1000),
        math.floor(lva.cur / 1000), math.floor(lva.max / 1000),
        math.floor(lsa.cur / 1000), math.floor(lsa.max / 1000),
        math.floor(cargo.cur / 1000), math.floor(cargo.max / 1000)
    )
    sampSendChat(msg)
end
