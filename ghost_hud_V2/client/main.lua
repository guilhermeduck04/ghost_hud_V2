local Config = {
    hudEnabled = true,
    showValues = false,
    minimapEnabled = true,
    elements = {
        health = { enabled = true, position = 'right' },
        armor = { enabled = true, position = 'right' },
        hunger = { enabled = true, position = 'right' },
        thirst = { enabled = true, position = 'right' },
        stamina = { enabled = true, position = 'right' },
        voice = { enabled = true, position = 'right' },
        vehicle = { enabled = true, position = 'left' },
        weapon = { enabled = true, position = 'right' },
        clock = { enabled = true, position = 'top' },
        money = { enabled = true, position = 'topright' },
        job = { enabled = true, position = 'topright' },
        id = { enabled = true, position = 'topright' },
        radiation = { enabled = true, position = 'right' },
        stress = { enabled = true, position = 'right' },
        temperature = { enabled = true, position = 'right' },
        hudImage = { enabled = true, position = 'top' }
    }
}

local QBCore = exports['qb-core']:GetCoreObject()
local hunger = 100
local thirst = 100
local stress = 0
local stamina = 100
local seatbelt = false
local playerLoaded = false
local lastStreet = nil

-- Função para garantir que o QBCore está carregado
local function EnsureQBCoreLoaded()
    while not QBCore do
        QBCore = exports['qb-core']:GetCoreObject()
        Wait(100)
    end
end

local function SendHUDConfigToNUI()
    SendNUIMessage({
        action = "updateHUD",
        config = Config
    })
    TriggerEvent('ghost-hud:updateConfig', Config)
end

-- Atualiza a rua atual do jogador
local function UpdateStreet()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local streetHash = GetStreetNameAtCoord(playerCoords.x, playerCoords.y, playerCoords.z)
    local streetName = GetStreetNameFromHashKey(streetHash)
    
    if streetName ~= lastStreet then
        lastStreet = streetName
        SendNUIMessage({
            action = "updateStreet",
            streetName = streetName
        })
    end
end

-- Funções auxiliares
local function IsSeatbeltOn()
    return seatbelt
end

RegisterCommand('seatbelt', function()
    seatbelt = not seatbelt
    TriggerEvent('chat:addMessage', {
        color = {255, 255, 255},
        args = {'[HUD]', seatbelt and 'Cinto de segurança colocado' or 'Cinto de segurança removido'}
    })
end, false)

RegisterKeyMapping('seatbelt', 'Alternar Cinto de Segurança', 'keyboard', 'B')

local function UpdateHUDPosition()
    SendNUIMessage({
        action = "updateHUD",
        config = Config
    })
end

-- Atualiza os status do jogador
local function UpdateStatus()
    if not playerLoaded then return end
    
    local ped = PlayerPedId()
    local health = (GetEntityHealth(ped) - 100)
    local armor = GetPedArmour(ped)
    stamina = 100 - GetPlayerSprintStaminaRemaining(PlayerId())
    local oxygen = IsPedSwimmingUnderWater(ped) and GetPlayerUnderwaterTimeRemaining(PlayerId()) * 10 or 100

    -- Obter dados do QBCore
    local playerData = QBCore.Functions.GetPlayerData()
    if playerData and playerData.metadata then
        hunger = playerData.metadata["hunger"] or hunger
        thirst = playerData.metadata["thirst"] or thirst
        stress = playerData.metadata["stress"] or stress
    end
    
    local radiation = playerData and playerData.metadata and playerData.metadata["radiation"] or 0

    local currentTemperature = exports['ghost_hud_V2']:GetTemperature()
    
    -- Lógica de Voz (integrada do voip.lua)
    local isTalking = LocalPlayer.state.isTalking
    local voiceLevel = LocalPlayer.state.proximity.index
    local voicePercent = 0
    if isTalking then
        if voiceLevel == 1 then -- Sussurro
            voicePercent = 33
        elseif voiceLevel == 2 then -- Normal
            voicePercent = 66
        elseif voiceLevel == 3 then -- Gritando
            voicePercent = 100
        else
            voicePercent = 66 -- Padrão
        end
    end

    SendNUIMessage({
        action = "updateStatus",
        health = health,
        armor = armor,
        hunger = hunger,
        thirst = thirst,
        stamina = stamina,
        oxygen = oxygen,
        radiation = radiation * 100,
        stress = stress * 100,
        isTalking = isTalking,
        voicePercent = voicePercent,
        temperature = currentTemperature
    })
end

-- Atualiza os dados do jogador (dinheiro, trabalho, etc)
local function UpdatePlayerData()
    local playerData = QBCore.Functions.GetPlayerData()
    if not playerData then return end
    
    local serverId = GetPlayerServerId(PlayerId())
    
    SendNUIMessage({
        action = "updatePlayerData",
        money = playerData.money and playerData.money['cash'] or 0,
        job = playerData.job and playerData.job.label or "Desempregado",
        jobGrade = playerData.job and playerData.job.grade.name or "",
        serverId = serverId,
        citizenId = playerData.citizenid or "0000"
    })
    SendHUDConfigToNUI()
end


-- Evento para atualizar quando o dinheiro mudar
RegisterNetEvent('QBCore:Client:OnMoneyChange', function()
    UpdatePlayerData()
end)

-- Evento para atualizar quando o trabalho mudar
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    UpdatePlayerData()
end)

-- Eventos NUI
RegisterNUICallback('updateMinimap', function(data, cb)
    local show = data.show
    Config.minimapEnabled = show
    DisplayRadar(show)
    cb({})
end)

RegisterNUICallback('toggleHUD', function(data, cb)
    Config.hudEnabled = data.state
    SendNUIMessage({
        action = "updateHUD",
        config = Config
    })
    DisplayRadar(Config.hudEnabled and Config.minimapEnabled)
    cb({})
end)

RegisterNUICallback('getGameTime', function(_, cb)
    local hour = GetClockHours()
    local minute = GetClockMinutes()
    cb({ hours = hour, minutes = minute })
end)

RegisterNUICallback('closeConfig', function(_, cb)
    SetNuiFocus(false, false)
    cb({})
end)

-- Eventos do servidor
RegisterNetEvent('ghost-hud:updateConfig', function(config)
    Config = config
    SendNUIMessage({
        action = "updateHUD",
        config = Config
    })
end)

RegisterNetEvent('ghost-hud:forceOpenConfig', function()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'forceShowConfig',
        config = Config
    })
end)

-- Comandos
RegisterCommand('hudconfig', function()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'forceShowConfig',
        config = Config
    })
end, false)
RegisterKeyMapping('hudconfig', 'Abrir Configuração do HUD', 'keyboard', 'F2')

-- Threads principais
CreateThread(function()
    EnsureQBCoreLoaded() -- Garante que o QBCore está carregado
    
    -- Espera o jogador carregar
    while not playerLoaded do
        Wait(500)
    end
    
    -- Inicializa o HUD
    UpdatePlayerData()
    UpdateStatus()
    UpdateStreet()
    SendHUDConfigToNUI()
    
    -- Ativa o minimapa se configurado
    DisplayRadar(Config.minimapEnabled)
end)

-- Thread para atualização contínua do status
CreateThread(function()
    while true do
        Wait(200)
        if Config.hudEnabled and playerLoaded then
            UpdateStatus()
            UpdateStreet()
            DisplayAmmoThisFrame(false)
        end
    end
end)

-- Thread para informações do veículo
CreateThread(function()
    while true do
        Wait(500)
        if Config.hudEnabled and Config.elements.vehicle.enabled and playerLoaded then
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped) then
                local veh = GetVehiclePedIsIn(ped, false)
                local speed = math.floor(GetEntitySpeed(veh) * 3.6)
                local fuel = GetVehicleFuelLevel(veh)
                local engine = GetIsVehicleEngineRunning(veh)
                local locked = GetVehicleDoorLockStatus(veh) > 1
                seatbelt = IsSeatbeltOn()
                
                local rpm = GetVehicleCurrentRpm(veh)
                local gear = GetVehicleCurrentGear(veh)
                
                if GetVehicleCurrentGear(veh) == 0 then
                    gear = IsVehicleInBurnout(veh) and 0 or -1
                end

                SendNUIMessage({
                    action = "vehicleHUD",
                    show = true,
                    speed = speed,
                    fuel = fuel,
                    engine = engine,
                    locked = locked,
                    seatbelt = seatbelt,
                    rpm = rpm,
                    gear = gear
                })
            else
                SendNUIMessage({ action = "vehicleHUD", show = false })
            end
        end
    end
end)

-- Thread para informações da arma
CreateThread(function()
    while true do
        Wait(300)
        if Config.hudEnabled and Config.elements.weapon.enabled and playerLoaded then
            local ped = PlayerPedId()
            local weapon = GetSelectedPedWeapon(ped)
            if weapon ~= `WEAPON_UNARMED` then
                local ammoTotal = GetAmmoInPedWeapon(ped, weapon)
                local _, ammoClip = GetAmmoInClip(ped, weapon)
                if ammoClip == -1 then
                    ammoClip = ammoTotal
                end
                
                local ammoInventory = ammoTotal - ammoClip

                SendNUIMessage({
                    action = "updateWeapon",
                    weapon = weapon,
                    ammoTotal = ammoTotal,
                    ammoClip = ammoClip,
                    ammoInventory = ammoInventory
                })
            else
                SendNUIMessage({ action = "hideWeapon" })
            end
        end
    end
end)

AddEventHandler('pma-voice:setTalkingMode', function(mode)
    SendNUIMessage({
        action = "updateVoiceMode",
        mode = mode -- "whisper", "normal", "shout"
    })
end)

-- Adicione isso na seção de inicialização (perto dos outros eventos de rádio)
CreateThread(function()
    while true do
        Wait(1000) -- Verifica a cada segundo
        local radioChannel = LocalPlayer.state.radioChannel or 0
        
        SendNUIMessage({
            action = "updateRadio",
            show = radioChannel > 0,
            frequency = radioChannel > 0 and (radioChannel .. ".0 MHz") or "OFF"
        })
    end
end)

-- Mantenha também esses eventos para atualizações em tempo real
AddEventHandler('pma-voice:radioActive', function(isRadioOn, radioChannel)
    SendNUIMessage({
        action = "updateRadio",
        show = isRadioOn,
        frequency = radioChannel and (radioChannel .. ".0 MHz") or "OFF"
    })
end)

AddEventHandler('pma-voice:radioChannel', function(radioChannel)
    SendNUIMessage({
        action = "updateRadio",
        show = radioChannel ~= 0,
        frequency = radioChannel and (radioChannel .. ".0 MHz") or "OFF"
    })
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    -- Verifica o estado do rádio após 1 segundo (tempo para carregar tudo)
    Wait(1000)
    local radioChannel = LocalPlayer.state.radioChannel or 0
    SendNUIMessage({
        action = "updateRadio",
        show = radioChannel > 0,
        frequency = radioChannel > 0 and (radioChannel .. ".0 MHz") or "OFF"
    })
end)


-- Eventos do QBCore
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    playerLoaded = true
    local playerData = QBCore.Functions.GetPlayerData()
    
    if playerData and playerData.metadata then
        hunger = playerData.metadata["hunger"] or 100
        thirst = playerData.metadata["thirst"] or 100
        stress = playerData.metadata["stress"] or 0
    end
    
    UpdatePlayerData()
    UpdateStatus()
    UpdateStreet()

    -- Verifica o estado inicial do rádio
    local radioChannel = LocalPlayer.state.radioChannel
    if radioChannel and radioChannel > 0 then
        SendNUIMessage({
            action = "updateRadio",
            show = true,
            frequency = radioChannel .. ".0 MHz"
        })
    end
    
    -- Força uma atualização completa após 1 segundo (garantia)
    Wait(1000)
    UpdatePlayerData()
    UpdateStatus()
    SendHUDConfigToNUI()
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(newData)
    if not playerLoaded then return end
    
    if newData.metadata then
        hunger = newData.metadata["hunger"] or hunger
        thirst = newData.metadata["thirst"] or thirst
        stress = newData.metadata["stress"] or stress
    end
    
    UpdatePlayerData()
    SendHUDConfigToNUI()
end)


-- Inicialização final
CreateThread(function()
    Wait(1000) -- Espera inicial
    UpdateStreet() -- Atualiza a rua logo no início
    
    -- Verifica se o jogador já está carregado (caso de reconnect)
    if LocalPlayer.state.isLoggedIn then
        playerLoaded = true
        UpdatePlayerData()
        UpdateStatus()
        SendHUDConfigToNUI()
    end
end)