script_name("SupplyReports")
script_author("OpenAI")

local vkeys = require 'vkeys'
local sampev = require 'samp.events'

local currentTonn = "0/500"
local currentPortTonn = "0/200"
local awaitingPostUnloadTarget = nil
local awaitingLoadedMaterials = false
local pendingCarmAction = nil
local pendingCarmUntil = 0

local function sendDelayed(ms, fn)
    lua_thread.create(function()
        wait(ms)
        fn()
    end)
end

local function armCarmHook(action)
    pendingCarmAction = action
    pendingCarmUntil = os.clock() + 3.0
    sampSendChat("/carm")
end

local function sendCarmAndPickFirst()
    armCarmHook("first")
end

local function sendCarmAndPickLast()
    armCarmHook("last")
end

local function getMyId()
    local _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
    return tostring(id or 0)
end

local function processReport(text)
    text = text:gsub("id", getMyId())
    text = text:gsub("tonn", tostring(currentTonn))
    return text
end

-- ===== ДОКЛАДЫ =====

local function report1040LVa()
    sampSendChat(processReport("/r Борт id. 10-40."))
    sendDelayed(350, function()
        sendCarmAndPickFirst()
    end)
end

local function report1040LS()
    sampSendChat(processReport("/r Борт id. 10-40. Порт ЛС."))
    sendDelayed(350, function()
        sendCarmAndPickFirst()
    end)
end

local function report1041LVa()
    sampSendChat(processReport("/r Борт id. 10-41. ЛВа."))
    sendDelayed(2000, function()
        sendCarmAndPickLast()
    end)
end

local function report1041LS()
    sampSendChat(processReport("/r Борт id. 10-41. Порт ЛС."))
    sendDelayed(2000, function()
        sendCarmAndPickLast()
    end)
end

local function report1042LVa()
    sampSendChat(processReport("/r Борт id. 10-42. ЛВа tonn."))
end

local function report1042LS()
    sampSendChat(processReport("/r Борт id. 10-42. Порт ЛС " .. currentPortTonn .. "."))
end

local function report1044()
    sampSendChat(processReport("/r Борт id. 10-44."))
end

function main()
    while not isSampAvailable() do
        wait(100)
    end

    sampAddChatMessage("{FF5F5F}[Supply]{FFFFFF}: автодоклады поставок загружены.", -1)

    while true do
        wait(0)

        -- РУЧНЫЕ ДОКЛАДЫ ЛВа
        if isKeyDown(vkeys.VK_J) and isKeyJustPressed(vkeys.VK_6) then report1040LVa() end
        if isKeyDown(vkeys.VK_J) and isKeyJustPressed(vkeys.VK_7) then report1041LVa() end
        if isKeyDown(vkeys.VK_J) and isKeyJustPressed(vkeys.VK_8) then report1042LVa() end

        -- РУЧНЫЕ ДОКЛАДЫ ПОРТ ЛС
        if isKeyDown(vkeys.VK_K) and isKeyJustPressed(vkeys.VK_6) then report1040LS() end
        if isKeyDown(vkeys.VK_K) and isKeyJustPressed(vkeys.VK_7) then report1041LS() end
        if isKeyDown(vkeys.VK_K) and isKeyJustPressed(vkeys.VK_8) then report1042LS() end

        -- J+9 = 10-44
        if isKeyDown(vkeys.VK_J) and isKeyJustPressed(vkeys.VK_9) then report1044() end

        -- J+0 = ручной доклад 10-45
        if isKeyDown(vkeys.VK_J) and isKeyJustPressed(vkeys.VK_0) then
            sampSetChatInputEnabled(true)
            sampSetChatInputText(processReport("/r Борт id. 10-45. Листраж: "))
        end
    end
end

function sampev.onShowDialog(dialogId, style, title, button1, button2, dialogText)
    if not pendingCarmAction then return end
    if os.clock() > pendingCarmUntil then
        pendingCarmAction = nil
        pendingCarmUntil = 0
        return
    end
    if style ~= 2 and style ~= 4 and style ~= 5 then return end

    local body = dialogText or ""
    local rows = {}

    for line in body:gmatch("[^\r\n]+") do
        if line:match("%S") then table.insert(rows, line) end
    end

    if #rows == 0 then return end

    local action = pendingCarmAction
    pendingCarmAction = nil
    pendingCarmUntil = 0
    local item = 0

    if action == "last" then
        if style == 5 then
            item = math.max(0, #rows - 2)
        else
            item = math.max(0, #rows - 1)
        end
    end

    lua_thread.create(function()
        wait(0)
        sampSendDialogResponse(dialogId, 1, item, "")
    end)

    return false
end

function sampev.onServerMessage(color, text)
    local clean = text:gsub("{......}", "")
    clean = clean:gsub("^%s+", ""):gsub("%s+$", "")

    -- После завершения загрузки ждём строку с фактическим количеством
    if clean:find("Загрузка материалов завершена", 1, true) then
        awaitingLoadedMaterials = true
        return
    end

    if awaitingLoadedMaterials then
        local currentMat, maxMat = clean:match("Материалов[^:]*:%s*(%d+)%s*/%s*(%d+)")
        if currentMat and maxMat and currentMat == maxMat then
            awaitingLoadedMaterials = false
            if maxMat == "30000" then report1041LVa()
            elseif maxMat == "50000" then report1041LS() end
            return
        end
    end

    -- После полной разгрузки запоминаем, куда выполнялась поставка.
    local matCurrent, matMax = clean:match("Материалов[^:]*:%s*(%d+)%s*/%s*(%d+)")
    if matCurrent and matMax and tonumber(matCurrent) == 0 then
        if tonumber(matMax) == 30000 then awaitingPostUnloadTarget = "lva"
        elseif tonumber(matMax) == 50000 then awaitingPostUnloadTarget = "ls" end
        return
    end

    -- Получаем состояние склада ЛВа
    local current, max = clean:match("На складе%s+Army%s+LV:%s*(%d+)%/(%d+)")
    if not current then current, max = clean:match("Army%s+LV:%s*(%d+)%/(%d+)") end

    if current and max then
        currentTonn = tostring(math.floor(tonumber(current) / 1000)) .. "/500"
        if awaitingPostUnloadTarget == "lva" then
            awaitingPostUnloadTarget = nil
            report1042LVa()
            if tonumber(current) < 490000 then
                sendDelayed(350, function() sendCarmAndPickFirst() end)
            else
                sendDelayed(350, function() report1044() end)
            end
        end
    end

    -- Получаем состояние склада Порта ЛС
    local portCurrent, portMax = clean:match("На складе%s+Порту%s+LS:%s*(%d+)%/(%d+)")
    if not portCurrent then portCurrent, portMax = clean:match("Порту%s+LS:%s*(%d+)%/(%d+)") end

    if portCurrent and portMax then
        currentPortTonn = tostring(math.floor(tonumber(portCurrent) / 1000)) .. "/200"
        if awaitingPostUnloadTarget == "ls" then
            awaitingPostUnloadTarget = nil
            report1042LS()
            if tonumber(portCurrent) < 185000 then
                sendDelayed(350, function() sendCarmAndPickFirst() end)
            else
                sendDelayed(350, function() report1044() end)
            end
        end
    end
end
