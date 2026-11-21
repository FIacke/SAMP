script_author = "Gorskin"
script_name = "[GangMaster]"
script_properties('work-in-pause')
local ev = require "lib.samp.events"
local imgui = require 'imgui'
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8
local rkeys = require 'rkeys'
local vkeys = require 'vkeys'
local memory = require("memory")
local wm = require 'windows.message'
imgui.HotKey = require('imgui_addons').HotKey
local ffi = require("ffi")
local inicfg = require "inicfg"
local directIni = "GANGMASTER.ini"
local ini = inicfg.load({
    settings = {
        automati = true,
        gun = 0,
        buffgun = 50,
        cenagun = 5,
        cenanarko = 25,
        buffnarko = 50,
        fixcarspawn = false,
        drugs_key = "[88]",
        sbiv_key = "[82]",
        fastaction_key = "[72]",
        docraft_key = "[114]",
        ahelame = false,
        acpat_key = "[53]",
        doublejump_key = "[90]",
        doublejump_keyPrig = 16,
        sbiv = false,
        docraftpatrons = 10,
        acaptcd = 900,
        acapt = false,
        delbeat = false,
        doublejump = false,
        disaFlyingComponent = false,
        cenakey = 100,
    },
}, directIni)
inicfg.save(ini, directIni)

local minicmds = {}

local sw, sh = getScreenResolution()
local imgui_main = {
    menu = {
        main_menu = imgui.ImBool(false),
        fastact_menu = imgui.ImBool(false),
        peredachagana_menu = imgui.ImBool(false),
        peredachanarko_menu = imgui.ImBool(false),
    },
    checkboxes = {
        automati = imgui.ImBool(ini.settings.automati),
        sbiv = imgui.ImBool(ini.settings.sbiv),
        acapt = imgui.ImBool(ini.settings.acapt),
        delbeat = imgui.ImBool(ini.settings.delbeat),
        doublejump = imgui.ImBool(ini.settings.doublejump),
        disaFlyingComponent = imgui.ImBool(ini.settings.disaFlyingComponent),
        fixcarspawn = imgui.ImBool(ini.settings.fixcarspawn),
        ahelame = imgui.ImBool(ini.settings.ahelame),
    },
    int = {
        gun = imgui.ImInt(ini.settings.gun),
    },
    buffers = {
        gun = imgui.ImInt(ini.settings.buffgun),
        cenagun = imgui.ImInt(ini.settings.cenagun),
        cenakey = imgui.ImInt(ini.settings.cenakey),
        narko = imgui.ImInt(ini.settings.buffnarko),
        cenanarko = imgui.ImInt(ini.settings.cenanarko),
        origcmd = imgui.ImBuffer(128),
        multilineText = imgui.ImBuffer(14000),
        docraftpatrons = imgui.ImInt(ini.settings.docraftpatrons),
        acaptcd = imgui.ImInt(ini.settings.acaptcd),
        doublejump_keyPrig = imgui.ImInt(ini.settings.doublejump_keyPrig),
    },
}

local acapt = false

function save()
    inicfg.save(ini, directIni)
end

function getweaponname(weapon)
    local names = {
    [0] = "Fist",
    [1] = "Brass Knuckles",
    [2] = "Golf Club",
    [3] = "Nightstick",
    [4] = "Knife",
    [5] = "Baseball Bat",
    [6] = "Shovel",
    [7] = "Pool Cue",
    [8] = "Katana",
    [9] = "Chainsaw",
    [10] = "Purple Dildo",
    [11] = "Dildo",
    [12] = "Vibrator",
    [13] = "Silver Vibrator",
    [14] = "Flowers",
    [15] = "Cane",
    [16] = "Grenade",
    [17] = "Tear Gas",
    [18] = "Molotov Cocktail",
    [22] = "9mm",
    [23] = "Silenced 9mm",
    [24] = "Deagle",
    [25] = "Shotgun",
    [26] = "Sawnoff Shotgun",
    [27] = "Combat Shotgun",
    [28] = "Micro SMG/Uzi",
    [29] = "MP5",
    [30] = "AK-47",
    [31] = "M4",
    [32] = "Tec-9",
    [33] = "Rifle",
    [34] = "Sniper Rifle",
    [35] = "RPG",
    [36] = "HS Rocket",
    [37] = "Flamethrower",
    [38] = "Minigun",
    [39] = "Satchel Charge",
    [40] = "Detonator",
    [41] = "Spraycan",
    [42] = "Fire Extinguisher",
    [43] = "Camera",
    [44] = "Night Vis Goggles",
    [45] = "Thermal Goggles",
    [46] = "Parachute" }
    return names[weapon]
end

local tLastKeys = {} -- предыдущие хоткеи активации

local DrugsKey = {
	v = decodeJson(ini.settings.drugs_key)
}

local SbivKey = {
	v = decodeJson(ini.settings.sbiv_key)
}

local DocraftGun = {
    v = decodeJson(ini.settings.docraft_key)
}

local aCapt = {
    v = decodeJson(ini.settings.acpat_key)
}

local FastAction = {
	v = decodeJson(ini.settings.fastaction_key)
}

local DoubleJump = {
	v = decodeJson(ini.settings.doublejump_key)
}

local created = false
local proverka = false
local proverka2 = false
local getcd = false
local timernarko = 0
local cd = timernarko
local LFID = nil

local weapons = {
    "Deagle",
    "Sdpistol",
    "Rifle",
    "Shotgun",
    "SMG",
    "AK47",
    "M4",
}

local dance = false

function main()
	repeat wait(100) until isSampAvailable()
    memory.fill(sampGetBase() + 0x7418, 0x90, 6, true) -- patch hide hud off
    cfile()
    if imgui_main.buffers.multilineText.v == "" then
        imgui_main.buffers.multilineText.v = u8(table.concat(minicmds, "\n"))
    end
    while sampGetGamestate() ~= 3 do return true end
    wait(1000)
    sampRegisterChatCommand("gmaster", function()
        imgui_main.menu.main_menu.v = not imgui_main.menu.main_menu.v
        imgui.Process = imgui_main.menu.main_menu.v
    end)
    sampRegisterChatCommand("gsell", function(arg)
        local id = tonumber(arg)
        if id == nil then
            sampAddChatMessage(script_name.." {FFFFFF}Вы не указали ид!", 0x73b461)
        end
        if type(id) ~= 'number' then
            sampAddChatMessage(script_name.." {FFFFFF}Используйте: {dc4747}/gsell [id]", 0x73b461)
        else
            if sampIsPlayerConnected(id) then
                LFID = id
                imgui_main.menu.fastact_menu.v = true
            else
                sampAddChatMessage(script_name.." {FFFFFF}Игрок не найден!", 0x73b461)
            end
        end
    end)
    

    
    sampAddChatMessage(script_name.." {FFFFFF}Загружен. {FFFFFF}Настройки: {dc4747}/gmaster {FFFFFF}Автор: {dc4747}"..script_author, 0x73b461)
    lua_thread.create(timer_narko)
    bindUsedrugs = rkeys.registerHotKey(DrugsKey.v, true, function()
        if timernarko == 0 and not sampIsCursorActive() then
            getcd = true
            sampSendChat("/boostinfo")
            wait(500)
        end
        if timernarko > 0 and not sampIsCursorActive() then
            local kol_narko = tostring(160/10 - math.modf(getCharHealth(PLAYER_PED)/10))
            if tonumber(kol_narko) >= 16 then
                kol_narko = 15
            end
            sampSendChat("/usedrugs "..kol_narko)
        end
    end)
    lua_thread.create(autocapt)

    -------------------[ Func ]---------------
    gotofunc("all")
    ------------------------------------------
    while true do wait(0)
        second_timer = os.difftime(os.time(), timernarko)
        if isKeyJustPressed(string.match(encodeJson(aCapt.v), "%[(%d+)%]")) and ini.settings.acapt and not sampIsCursorActive() then
            acapt = not acapt
            printStringNow(acapt and "~W~GangMaster (autocapt): ~G~ON" or "~W~GangMaster (autocapt): ~R~OFF", 2000)
        end

        if isKeyJustPressed(string.match(encodeJson(DoubleJump.v), "%[(%d+)%]")) and ini.settings.doublejump and not sampIsCursorActive() then
            --sampSendChat("/anim 6 7")
            taskPlayAnimNonInterruptable(PLAYER_PED, "colt45_reload", "COLT45", 4.0999999046326, false, false, true, true, 1)
			for i = 1, 10 do
                if i == 3 then taskPlayAnimNonInterruptable(PLAYER_PED, "colt45_reload", "COLT45", 4.0999999046326, false, false, true, true, 1) end
				setVirtualKeyDown(tonumber(ini.settings.doublejump_keyPrig), true)
				wait(2)
				setVirtualKeyDown(tonumber(ini.settings.doublejump_keyPrig), false)
                wait(12)
			end
        end

        if proverka and sampIsLocalPlayerSpawned() and not created then
            sampTextdrawCreate(1349, "_", 5000, 5000)	
            created = true
        end
        if proverka and created and not sampTextdrawIsExists(1349) then
            created = false
        end
        if not created and not proverka then
            if sampTextdrawIsExists(1349) then created = false proverka = false sampTextdrawDelete(1349) end
        end 
        if proverka and created then
            if cd > 0 then
                sampTextdrawSetLetterSizeAndColor(1349, 0.240, 1.000, 4294967295)
                sampTextdrawSetPos(1349, 564, 122)
                sampTextdrawSetStyle(1349, 2)
                sampTextdrawSetBoxColorAndSize(1349, 1, 0x45030002, 700, 150)
                sampTextdrawSetOutlineColor(1349, 1, 4278190080)
                sampTextdrawSetString(1349, "~W~DRUGS:_~r~"..("%02d"):format(cd).."_~W~SEC")
            else
                if sampTextdrawIsExists(1349) then created = false proverka = false sampTextdrawDelete(1349) end
            end
        end
        if imgui_main.checkboxes.sbiv.v and isKeyJustPressed(string.match(encodeJson(SbivKey.v), "%[(%d+)%]")) and isCharOnFoot(PLAYER_PED) and not sampIsCursorActive() then
            sampSetSpecialAction(7)
        elseif wasKeyReleased(string.match(encodeJson(SbivKey.v), "%[(%d+)%]")) then
            sampSetSpecialAction(0)
        end

        if ini.settings.delbeat and getCurrentCharWeapon(PLAYER_PED) == 5 then
            removeWeaponFromChar(PLAYER_PED, 5)
        end

        if isKeyJustPressed(string.match(encodeJson(DocraftGun.v), "%[(%d+)%]")) then
            if getCurrentCharWeapon(PLAYER_PED) ~= 0 then
                local gun = getCurrentCharWeapon(PLAYER_PED)
                sampSendChat("/gun "..getweaponname(gun).." "..ini.settings.docraftpatrons)
            end
        end
        local valid, ped = getCharPlayerIsTargeting(PLAYER_HANDLE)
        if valid and doesCharExist(ped) then 
            local result, tid = sampGetPlayerIdByCharHandle(ped)
            if result and isKeyJustPressed(string.match(encodeJson(FastAction.v), "%[(%d+)%]")) then
                LFID = tid
                imgui_main.menu.fastact_menu.v = true
            end
        end
        imgui.Process = imgui_main.menu.main_menu.v or imgui_main.menu.fastact_menu.v or imgui_main.menu.peredachagana_menu.v or imgui_main.menu.peredachanarko_menu.v
    end
end

function timer_narko()
    while true do
        wait(0)
        while 0 < tonumber(cd) do			
            wait(998)
            cd = cd - 1
        end
    end
end

function autocapt()
    while true do
        wait(0)
        if acapt then
            sampSendChat("/capture 0")
            wait(tonumber(ini.settings.acaptcd))
        end
    end
end

local last = 0

local aheal = true

function ev.onServerMessage(color, text)
    if text:find("У вас %d/%d материалов с собой") and mats == nil then
        mats = text:match("У вас (%d+)/%d материалов с собой")
        print(mats)
    end
    if text:find("(( Остаток: %d+ грамм ))") then
        proverka = true
        cd = timernarko
    end
    if getcd and text:find("Бонусы отключены") then
        timernarko = 60
        sampAddChatMessage(script_name.." {FFFFFF}Таймер на нарко: {dc4747}"..timernarko.." {FFFFFF}секунд", 0x73b461)
        save()
        getcd = false
        return false
    end
    if ini.settings.ahelame then 
        if text:find("Сейчас не получится. Вы используете намного больше аптечек, чем остальные") or text:find("Вы должны быть на своей базе или дома") or text:find("Вы не нуждаетесь в лечении") then
            aheal = false
        end
    end
    if getcd and text:find("Действует до:") then
        return false
    end
    if text:find(".+%sоткрыл%(а%)%sсклад%sс%sоружием") and ini.settings.automati and last == 0 then
        last = 1
        lua_thread.create(function()
            wait(100)
            sampSendChat("/get guns")
            wait(1200)
            last = 0
        end)
    end
end

function ev.onShowDialog(id, style, title, button1, button2, text)
    if getcd then
        if title:find("Бонусы") then
            for line in text:gmatch("[^\n]+") do
                if line:find("Таймер на Нарко") then
                    bonus = line:match("Таймер на Нарко	(.+)")
                    timernarko = math.floor(bonus * 60 )
                    if timernarko < 22 then
                        timernarko = 30
                    end
                    sampAddChatMessage(script_name.." {FFFFFF}Таймер на нарко: {dc4747}"..timernarko.." {FFFFFF}секунд", 0x73b461)
                    getcd = false
                end
            end
            sampSendDialogResponse(id, 0, _, _)
            return false
        end
    end
end

function ev.onSendSpawn()
    
    cd = 0
    if ini.settings.fixcarspawn then
        lua_thread.create(function()
            wait(2000)
            sampSendChat("/fixcar")
        end)
    end
    if ini.settings.ahelame then
        lua_thread.create(function()
            repeat
                wait(1200)
                sampSendChat("/healme")
            until getCharHealth(PLAYER_PED) < 99 or not aheal
            
        end)
    end
    aheal = true
    
end

function gotofunc(fnc)
    if fnc == "DisaFlyingComponent" or fnc == "all" then
        if ini.settings.disaFlyingComponent then
            ffi.fill(ffi.cast(ffi.typeof('void*'), 0x6A85CC), 5, 0x90)
        else
            hex2bin("E82F8C1400", 0x6A85CC, 5)
        end
    end
end


function imgui.OnDrawFrame()
    if imgui_main.menu.main_menu.v then
        imgui.SetNextWindowSize(imgui.ImVec2(450, 500), imgui.Cond.FirstUseEver)
		imgui.SetNextWindowPos(imgui.ImVec2((sw / 2), sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.Begin(u8"Gang Master", imgui_main.menu.main_menu, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.AlwaysAutoResize)
            imgui.Text(u8"Клавиша для использования нарко:")
            imgui.SameLine()
            if imgui.HotKey(u8"##drugkey", DrugsKey, tLastKeys, 50) then
                rkeys.changeHotKey(bindUsedrugs, DrugsKey.v)
                sampAddChatMessage(script_name.." {FFFFFF}Старое значение: {dc4747}" .. table.concat(rkeys.getKeysName(tLastKeys.v), " + ") .. "{ffffff} | Новое: {dc4747}" .. table.concat(rkeys.getKeysName(DrugsKey.v), " + "), 0x73b461)
                ini.settings.drugs_key = encodeJson(DrugsKey.v)
                save()
            end
            if imgui.Checkbox(u8"DisaFlyingComponent (детали транспорта при поломке пропадают моментально)", imgui_main.checkboxes.disaFlyingComponent) then
                ini.settings.disaFlyingComponent = not ini.settings.disaFlyingComponent
                save()
                gotofunc("DisaFlyingComponent")
            end
            if imgui.Checkbox(u8"Fixcar при спавне", imgui_main.checkboxes.fixcarspawn) then
                ini.settings.fixcarspawn = not ini.settings.fixcarspawn
                save()
            end
            if imgui.Checkbox(u8"Авто /healme до 100 хп при спавне", imgui_main.checkboxes.ahelame) then
                ini.settings.ahelame = not ini.settings.ahelame
                save()
            end

            if imgui.Checkbox(u8"Double Jump", imgui_main.checkboxes.doublejump) then
                ini.settings.doublejump = not ini.settings.doublejump
                save()
            end
         
            if ini.settings.doublejump then
                imgui.Text(u8"Клавиша для Double Jump:")
                imgui.SameLine()
                if imgui.HotKey(u8"##djm44p", DoubleJump, tLastKeys, 50) then
                    sampAddChatMessage(script_name.." {FFFFFF}Старое значение: {dc4747}" .. table.concat(rkeys.getKeysName(tLastKeys.v), " + ") .. "{ffffff} | Новое: {dc4747}" .. table.concat(rkeys.getKeysName(DoubleJump.v), " + "), 0x73b461)
                    ini.settings.doublejump_key = encodeJson(DoubleJump.v)
                    save()
                end
                imgui.Text(u8"Клавиша которую вы жмёте чтобы прыгать:")
                imgui.SameLine()
                imgui.PushItemWidth(90)
                if imgui.InputInt(u8"##djmpprk", imgui_main.buffers.doublejump_keyPrig) then
                    ini.settings.doublejump_keyPrig = imgui_main.buffers.doublejump_keyPrig.v
                    save()
                end
                imgui.PopItemWidth()
            end
            imgui.Text(u8"Клавиша для докрафта патронов для оружия в руках:")
            imgui.SameLine()
            if imgui.HotKey(u8"##docraftkey", DocraftGun, tLastKeys, 50) then
                sampAddChatMessage(script_name.." {FFFFFF}Старое значение: {dc4747}" .. table.concat(rkeys.getKeysName(tLastKeys.v), " + ") .. "{ffffff} | Новое: {dc4747}" .. table.concat(rkeys.getKeysName(DocraftGun.v), " + "), 0x73b461)
                ini.settings.docraft_key = encodeJson(DocraftGun.v)
                save()
            end
            imgui.Text(u8"Количество патрон для докрафта:")
            imgui.SameLine()
            imgui.PushItemWidth(90)
            if imgui.InputInt(u8"##docraftpatr", imgui_main.buffers.docraftpatrons) then
                ini.settings.docraftpatrons = imgui_main.buffers.docraftpatrons.v
                save()
            end
            imgui.Text(u8"Цена за продажу ключей игроку через быстрое действие:")
            imgui.SameLine()
            if imgui.InputInt(u8"##cenakey", imgui_main.buffers.cenakey) then
                ini.settings.cenakey = imgui_main.buffers.cenakey.v
                save()
            end
            imgui.PopItemWidth()
            if imgui.Checkbox(u8"Сбив анимации", imgui_main.checkboxes.sbiv) then
                ini.settings.sbiv = not ini.settings.sbiv
                save()
            end
            
            if imgui_main.checkboxes.sbiv.v then
                imgui.Text(u8"Клавиша для сбива:")
                imgui.SameLine()
                if imgui.HotKey(u8"##sbivkey", SbivKey, tLastKeys, 50) then
                    sampAddChatMessage(script_name.." {FFFFFF}Старое значение: {dc4747}" .. table.concat(rkeys.getKeysName(tLastKeys.v), " + ") .. "{ffffff} | Новое: {dc4747}" .. table.concat(rkeys.getKeysName(SbivKey.v), " + "), 0x73b461)
                    ini.settings.sbiv_key = encodeJson(SbivKey.v)
                    save()
                end
            end
            if imgui.Checkbox(u8"АвтоКапт на клавишу", imgui_main.checkboxes.acapt) then
                ini.settings.acapt = not ini.settings.acapt
                save()
            end
            if imgui_main.checkboxes.acapt.v then
                imgui.Text(u8"Клавиша для запуска/остановки автокапта:")
                imgui.SameLine()
                if imgui.HotKey(u8"##acaptkey", aCapt, tLastKeys, 50) then
                    sampAddChatMessage(script_name.." {FFFFFF}Старое значение: {dc4747}" .. table.concat(rkeys.getKeysName(tLastKeys.v), " + ") .. "{ffffff} | Новое: {dc4747}" .. table.concat(rkeys.getKeysName(aCapt.v), " + "), 0x73b461)
                    ini.settings.acpat_key = encodeJson(aCapt.v)
                    save()
                end
                imgui.PushItemWidth(90)
                imgui.Text(u8"Задержка для автокапта:")
                if imgui.InputInt(u8"##acaptcd", imgui_main.buffers.acaptcd) then
                    ini.settings.acaptcd = imgui_main.buffers.acaptcd.v
                    save()
                end
                imgui.PopItemWidth()
            end
            if imgui.Checkbox(u8"Автоматическое взятие материалов при открытии склада", imgui_main.checkboxes.automati) then
                ini.settings.automati = imgui_main.checkboxes.automati.v
                save()
            end
            if imgui.Checkbox(u8"Автоматическое удаление биты", imgui_main.checkboxes.delbeat) then
                ini.settings.delbeat = imgui_main.checkboxes.delbeat.v
                save()
            end
            imgui.Text(u8"Быстрое действие с игроком: /gsell id")
            imgui.Text(u8"Клавиша для быстрого действия с игроком:")
            imgui.SameLine()
            imgui.Text(u8"ПКМ +")
            imgui.SameLine()
            if imgui.HotKey(u8"##fastactionforplayers", FastAction, tLastKeys, 50) then
                sampAddChatMessage(script_name.." {FFFFFF}Старое значение: {dc4747}" .. table.concat(rkeys.getKeysName(tLastKeys.v), " + ") .. "{ffffff} | Новое: {dc4747}" .. table.concat(rkeys.getKeysName(FastAction.v), " + "), 0x73b461)
                ini.settings.fastaction_key = encodeJson(FastAction.v)
                save()
            end
            imgui.Separator()
            imgui.Text(u8"Сократитель команд:\nПример использования: /оригинальная команда = /сокращенная команда")
            imgui.InputTextMultiline("##multilineText", imgui_main.buffers.multilineText, imgui.ImVec2(-1, 200))
            if imgui.Button(u8"Сохранить", imgui.ImVec2(200,20)) and imgui_main.buffers.multilineText.v ~= " " and imgui_main.buffers.multilineText.v ~= "" and imgui_main.buffers.multilineText.v ~= nil then
                if doesFileExist("moonloader\\gangmasterminicommands.txt") then
                    local path = getGameDirectory().."//moonloader//gangmasterminicommands.txt"
                    os.remove(path)
                    file = io.open("moonloader\\gangmasterminicommands.txt", "a+") -- открываем файл
                    file:write(string.format(""..u8:decode ( imgui_main.buffers.multilineText.v ).."\n") )
                    file:close()
                    minicmds = {}
                    cfile()
                end
            end
		imgui.End()
	end
    if imgui_main.menu.fastact_menu.v then
        imgui.SetNextWindowSize(imgui.ImVec2(300, 100), imgui.Cond.FirstUseEver)
		imgui.SetNextWindowPos(imgui.ImVec2((sw / 2), sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.Begin(u8"Gang Master [Быстрое действие]", imgui_main.menu.fastact_menu, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.AlwaysAutoResize)
            if sampIsPlayerConnected(LFID) then
                imgui.Text(u8"Взаимодействие с: "..sampGetPlayerNickname(LFID).." ("..LFID..")")
                if imgui.Button(u8"Продать оружие", imgui.ImVec2(200, 20)) then
                    imgui_main.menu.peredachagana_menu.v = true
                    imgui_main.menu.fastact_menu.v = false
                end
                if imgui.Button(u8"Продать наркотики", imgui.ImVec2(200, 20)) then
                    imgui_main.menu.peredachanarko_menu.v = true
                    imgui_main.menu.fastact_menu.v = false
                end
                if imgui.Button(u8"Принять в банду", imgui.ImVec2(200, 20)) then
                    sampSendChat("/invite "..LFID)
                end
                if imgui.Button(u8"Принять в SQUAD", imgui.ImVec2(200, 20)) then
                    sampSendChat("/squad invite "..LFID)
                end
                if imgui.Button(u8"Выдать ранг в банде", imgui.ImVec2(200, 20)) then
                    sampSendChat("/invite "..LFID)
                    sampSetChatInputText("/giverank "..LFID.." ")
                    sampSetChatInputEnabled(true)
                end
                if imgui.Button(u8"Дать ключи от камеры", imgui.ImVec2(200, 20)) then
                    sampSendChat("/sellekey "..LFID.." "..ini.settings.cenakey)
                end
            else
                imgui.Text(u8"Игрок для взаимодействия не найден!")
            end
            
		imgui.End()
    end
    if imgui_main.menu.peredachagana_menu.v then
        imgui.SetNextWindowSize(imgui.ImVec2(300, 160), imgui.Cond.FirstUseEver)
		imgui.SetNextWindowPos(imgui.ImVec2((sw / 2), sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.Begin(u8"Gang Master [Продажа оружия]", imgui_main.menu.peredachagana_menu, imgui.WindowFlags.NoCollapse)
            if sampIsPlayerConnected(LFID) then
                imgui.Text(u8"Продажа игроку: "..sampGetPlayerNickname(LFID).." ("..LFID..")")
            
                imgui.Text(u8"Оружие:")
                imgui.SameLine()
                imgui.PushItemWidth(130)
                if imgui.Combo(u8"##gun", imgui_main.int.gun, weapons, #weapons) then
                    ini.settings.gun = imgui_main.int.gun.v
                    save()
                end
                imgui.Text(u8"Количество патрон:")
                imgui.SameLine()
                imgui.PushItemWidth(90)
                if imgui.InputInt(u8"##patr", imgui_main.buffers.gun) then
                    ini.settings.buffgun = imgui_main.buffers.gun.v
                    save()
                end
                imgui.Text(u8"Цена:")
                imgui.SameLine()
                if imgui.InputInt(u8"##cena", imgui_main.buffers.cenagun) then
                    ini.settings.cenagun = imgui_main.buffers.cenagun.v
                    save()
                end
                if imgui.Button(u8"Продать", imgui.ImVec2(200, 20)) then
                    imgui_main.menu.peredachagana_menu.v = false
                    sampSendChat("/sellgun "..weapons[tonumber(imgui_main.int.gun.v+1)].." "..ini.settings.buffgun.." "..ini.settings.cenagun.." "..LFID)
                end
            else
                imgui.Text(u8"Игрок для взаимодействия не найден!")
            end
		imgui.End()
    end

    if imgui_main.menu.peredachanarko_menu.v then
        imgui.SetNextWindowSize(imgui.ImVec2(300, 130), imgui.Cond.FirstUseEver)
		imgui.SetNextWindowPos(imgui.ImVec2((sw / 2), sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.Begin(u8"Gang Master [Продажа наркотиков]", imgui_main.menu.peredachanarko_menu, imgui.WindowFlags.NoCollapse)
            if sampIsPlayerConnected(LFID) then
                imgui.Text(u8"Продажа игроку: "..sampGetPlayerNickname(LFID).." ("..LFID..")")
                imgui.Text(u8"Количество грамм:")
                imgui.SameLine()
                imgui.PushItemWidth(90)
                if imgui.InputInt(u8"##ngramm", imgui_main.buffers.narko) then
                    ini.settings.buffnarko = imgui_main.buffers.narko.v
                    save()
                end
                imgui.Text(u8"Цена:")
                imgui.SameLine()
                if imgui.InputInt(u8"##cenanarko", imgui_main.buffers.cenanarko) then
                    ini.settings.cenanarko = imgui_main.buffers.cenanarko.v
                    save()
                end
                if imgui.Button(u8"Продать", imgui.ImVec2(200, 20)) then
                    imgui_main.menu.peredachanarko_menu.v = false
                    sampSendChat("/selldrugs "..LFID.." "..ini.settings.buffnarko.." "..ini.settings.cenanarko)
                end
            else
                imgui.Text(u8"Игрок для взаимодействия не найден!")
            end
		imgui.End()
    end
end

function ev.onSendCommand(cmd)
    for i, v in ipairs(minicmds) do
        if minicmds[i] ~= "" and minicmds[i] ~= nil then
            orig, mini = string.match(u8:encode(v), "(.*) = (.*)")
            if orig ~= "" and orig ~= nil and mini ~= "" and mini ~= nil then
                if cmd:find("^"..mini.." .+") or cmd:find("^"..mini.."$") then
                    local args = cmd:match(mini.."(.*)")
                    cmd = orig..args
                    return {cmd}
                end
            end
        end
    end
end

function ev.onGivePlayerWeapon(weapon, ammo)
    if ini.settings.delbeat and weapon == 5 then
        return false
    end
end

function onWindowMessage(msg, wparam, lparam)
    if wparam == vkeys.VK_ESCAPE and imgui.Process then
        if msg == wm.WM_KEYDOWN then
            consumeWindowMessage(true, false)
        end
        if msg == wm.WM_KEYUP then
            imgui_main.menu.main_menu = imgui.ImBool(false)
            imgui_main.menu.fastact_menu = imgui.ImBool(false)
            imgui_main.menu.peredachagana_menu = imgui.ImBool(false)
            imgui_main.menu.peredachanarko_menu = imgui.ImBool(false)
        end
    end
end

function cfile()
    local file = io.open("moonloader\\gangmasterminicommands.txt", "a+") -- открываем и создаем файл
    file:close() -- закрываем, это если не будет файла то он создатся. Да да это гениально!
    local file = io.open("moonloader\\gangmasterminicommands.txt", "a+") -- открываем
    for line in file:lines() do -- читаем его построчно
        minicmds[#minicmds+1] = line -- записываем строки в массив
    end
    file:close() -- закрываем файл
    --
end


function hex2bin(hex, dst, size)
    if #hex == 0 or #hex % 2 ~= 0 then
        return false
    end
    if dst then
        if not size or size == 0 then
            return false
        end
        dst = ffi.cast('uint8_t*', dst)
        local idx = 0
        for i = 1, #hex, 2 do
            local byte = tonumber(hex:sub(i, i + 1), 16)
            if not byte then
                return false
            end
            dst[idx] = byte
            idx = idx + 1
            if idx >= size then
                return true
            end
        end
        return true
    else
        local str = {}
        for i = 1, #hex, 2 do
            local byte = tonumber(hex:sub(i, i + 1), 16)
            if not byte then
                return nil
            end
            str[#str + 1] = string.char(byte)
        end
        return table.concat(str)
    end
end

function purple_style()
	imgui.SwitchContext()
	local style = imgui.GetStyle()
	local colors = style.Colors
	local clr = imgui.Col
	local ImVec4 = imgui.ImVec4

	style.WindowRounding = 10
	style.ChildWindowRounding = 10
	style.FrameRounding = 6.0
	style.ItemSpacing = imgui.ImVec2(5.0, 5.0)
	style.ItemInnerSpacing = imgui.ImVec2(5.0, 5.0)
	style.IndentSpacing = 21
	style.ScrollbarSize = 10.0
	style.ScrollbarRounding = 13
	style.GrabMinSize = 17.0
	style.GrabRounding = 16.0

	style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
	style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
    colors[clr.FrameBg]                = ImVec4(0.46, 0.11, 0.29, 1.00)
	colors[clr.FrameBgHovered]         = ImVec4(0.69, 0.16, 0.43, 1.00)
	colors[clr.FrameBgActive]          = ImVec4(0.58, 0.10, 0.35, 1.00)
	colors[clr.TitleBg]                = ImVec4(0.00, 0.00, 0.00, 1.00)
	colors[clr.TitleBgActive]          = ImVec4(0.61, 0.16, 0.39, 1.00)
	colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
	colors[clr.CheckMark]              = ImVec4(0.94, 0.30, 0.63, 1.00)
	colors[clr.SliderGrab]             = ImVec4(0.85, 0.11, 0.49, 1.00)
	colors[clr.SliderGrabActive]       = ImVec4(0.89, 0.24, 0.58, 1.00)
	colors[clr.Button]                 = ImVec4(0.46, 0.11, 0.29, 1.00)
	colors[clr.ButtonHovered]          = ImVec4(0.69, 0.17, 0.43, 1.00)
    colors[clr.ButtonActive]           = ImVec4(0.59, 0.10, 0.35, 1.00)
	colors[clr.Header]                 = ImVec4(0.46, 0.11, 0.29, 1.00)
	colors[clr.HeaderHovered]          = ImVec4(0.69, 0.16, 0.43, 1.00)
	colors[clr.HeaderActive]           = ImVec4(0.58, 0.10, 0.35, 1.00)
	colors[clr.Separator]              = ImVec4(0.69, 0.16, 0.43, 1.00)
	colors[clr.SeparatorHovered]       = ImVec4(0.58, 0.10, 0.35, 1.00)
	colors[clr.SeparatorActive]        = ImVec4(0.58, 0.10, 0.35, 1.00)
	colors[clr.ResizeGrip]             = ImVec4(0.46, 0.11, 0.29, 0.70)
	colors[clr.ResizeGripHovered]      = ImVec4(0.69, 0.16, 0.43, 0.67)
	colors[clr.ResizeGripActive]       = ImVec4(0.70, 0.13, 0.42, 1.00)
	colors[clr.TextSelectedBg]         = ImVec4(1.00, 0.78, 0.90, 0.35)
	colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
	colors[clr.TextDisabled]           = ImVec4(0.60, 0.19, 0.40, 1.00)
	colors[clr.WindowBg]               = ImVec4(0.06, 0.06, 0.06, 0.94)
	colors[clr.ChildWindowBg]          = ImVec4(1.00, 1.00, 1.00, 0.00)
	colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
	colors[clr.ComboBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
	colors[clr.Border]                 = ImVec4(0.49, 0.14, 0.31, 1.00)
    colors[clr.BorderShadow]           = ImVec4(0.49, 0.14, 0.31, 0.00)
	colors[clr.MenuBarBg]              = ImVec4(0.15, 0.15, 0.15, 1.00)
	colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
	colors[clr.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
	colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
	colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
	colors[clr.CloseButton]            = ImVec4(0.20, 0.20, 0.20, 0.50)
	colors[clr.CloseButtonHovered]     = ImVec4(0.98, 0.39, 0.36, 1.00)
	colors[clr.CloseButtonActive]      = ImVec4(0.98, 0.39, 0.36, 1.00)
	colors[clr.ModalWindowDarkening]   = ImVec4(0.80, 0.80, 0.80, 0.35)
end
purple_style()

require("mimgui")
