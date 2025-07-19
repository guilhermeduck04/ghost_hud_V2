local QBCore = exports['qb-core']:GetCoreObject()
local playerLoaded = false

-- Variáveis de estado do jogador
local state = {
    currentTemperature = 25.0,      -- Temperatura efetiva que o jogador sente
    ambientTemperature = 25.0,      -- Temperatura real do ambiente
    playerWarmth = 0.0,             -- Isolamento das roupas
    isSheltered = false,            -- Está abrigado? (interior ou veículo)
    isWet = false,                  -- Está molhado?
    extremeTempTimer = 0,           -- Timer para dano
    activeScreenEffect = "none"     -- Efeito de tela ativo
}

----------------------------------------------------------------------------------------------------
-- CONFIGURAÇÕES GERAIS (AJUSTE TUDO AQUI)
----------------------------------------------------------------------------------------------------
local Config = {
    -- Geral
    UpdateInterval = 4000, -- Intervalo de atualização em ms (4 segundos para mais dinamismo)
    RoomTemperature = 22.0, -- Temperatura padrão para interiores
    DefaultTemp = 25.0, -- Temperatura padrão quando não está em nenhuma zona

    -- Dano por Temperatura
    EnableDamage = true,
    ColdDamageThreshold = -5.0, -- Dano por frio abaixo de -5°C
    HotDamageThreshold = 50.0,  -- Dano por calor acima de 50°C
    DamageAmount = 5,
    DamageInterval = 20000, -- 20 segundos

    -- Modificadores de Temperatura
    Modifiers = {
        NightTempDrop = 10.0, -- Quantos graus a temperatura cai à noite
        WetnessColdFactor = 5.0, -- Quantos graus a mais de frio você sente quando está molhado
        -- Modificadores baseados no clima do jogo
        Weather = {
            ['EXTRASUNNY'] = 5.0, ['CLEAR'] = 2.0, ['CLOUDS'] = 0.0,
            ['SMOG'] = -2.0, ['FOGGY'] = -4.0, ['OVERCAST'] = -5.0,
            ['RAIN'] = -8.0, ['THUNDER'] = -10.0, ['CLEARING'] = -3.0,
            ['NEUTRAL'] = 0.0, ['SNOW'] = -15.0, ['BLIZZARD'] = -20.0,
            ['SNOWLIGHT'] = -12.0, ['XMAS'] = -15.0, ['HALLOWEEN'] = -2.0,
        }
    },

    -- Roupas que protegem do FRIO (ajuste os valores de 'warmth' e IDs das roupas)
    WarmClothing = {
        [11] = { warmth = 5.0, drawables = { 15, 52, 55, 131, 147, 246, 261, 312, 351, 361, 395, 403 } }, -- Jaquetas e casacos
        [8] = { warmth = 3.0, drawables = { 14, 34, 131, 178, 188 } }, -- Suéteres
        [4] = { warmth = 2.0, drawables = { 31, 34, 100, 139 } }, -- Calças grossas
        [6] = { warmth = 1.0, drawables = { 12, 25, 35, 54 } }, -- Botas
    },

    -- Roupas que amenizam o CALOR (valores negativos)
    CoolClothing = {
        [11] = { warmth = -4.0, drawables = { 15, 18, 86 } }, -- Sem camisa, regatas
        [4] = { warmth = -3.0, drawables = { 14, 17, 61 } } -- Shorts
    },

    -- Efeitos Visuais de Tela
    ScreenEffects = {
        VeryCold = { threshold = 0.0, timecycle = "super_cold", strength = 0.4 },
        Freezing = { threshold = -10.0, timecycle = "super_cold", strength = 0.8, postfx = "FocusOut", postfx_duration = 10000 },
        VeryHot = { threshold = 45.0, timecycle = "heat_haze", strength = 0.3 },
        Burning = { threshold = 55.0, timecycle = "spectator_is_incinerating", strength = 0.5, postfx = "DrugsMichaelAliensFight", postfx_duration = 10000 }
    }
}

----------------------------------------------------------------------------------------------------
-- DADOS DO MUNDO (BIOMAS)
----------------------------------------------------------------------------------------------------
local ClimateZones = {
    -- Frio
    { name = "Mount Chiliad", center = vector3(466.1, 5585.9, 780.0), radius = 1000.0, baseTemp = -2.0 },
    { name = "Paleto Forest", center = vector3(215.1, 6632.4, 15.0), radius = 1200.0, baseTemp = 15.0 },
    -- Temperado
    { name = "Vinewood Hills", center = vector3(147.2, 747.2, 180.0), radius = 1000.0, baseTemp = 24.0 },
    { name = "Grand Senora", center = vector3(1750.0, 3119.0, 40.0), radius = 1200.0, baseTemp = 29.0 },
    -- Quente
    { name = "Sandy Shores", center = vector3(2169.1, 3632.5, 33.0), radius = 1500.0, baseTemp = 36.0 },
    { name = "Los Santos City", center = vector3(10.0, -800.0, 30.0), radius = 3000.0, baseTemp = 30.0 },
    -- Padrão
    { name = "Default", center = vector3(0.0, 0.0, 0.0), radius = 99999.0, baseTemp = Config.DefaultTemp } -- Zona padrão que cobre o mapa todo
}
table.sort(ClimateZones, function(a, b) return a.radius < b.radius end) -- Otimização para achar a zona mais específica primeiro

local VisualEffects = {
    { threshold = 40.0, dict = "scr_gr_heist_heat_haze", name = "scr_gr_heist_heat_haze", scale = 0.5 },
    { threshold = 5.0,  dict = "core", name = "ent_amb_cold_breath", scale = 1.0 },
}
local activeParticle, activeParticleName = nil, nil

----------------------------------------------------------------------------------------------------
-- FUNÇÕES DO SISTEMA
----------------------------------------------------------------------------------------------------

-- Export para que o main.lua possa obter a temperatura
exports('GetTemperature', function()
    return state.currentTemperature
end)

--- Verifica se o jogador está abrigado
local function IsPlayerSheltered(ped)
    if IsPedInAnyVehicle(ped, false) then return true end
    local interiorId = GetInteriorFromEntity(ped)
    if interiorId ~= 0 then return true end
    return false
end

--- Calcula o isolamento térmico (incluindo umidade)
local function UpdatePlayerWarmth(ped)
    local warmthScore = 0.0
    
    -- Verifica roupas quentes
    for componentId, data in pairs(Config.WarmClothing) do
        local drawable = GetPedDrawableVariation(ped, componentId)
        for _, validDrawable in ipairs(data.drawables) do
            if drawable == validDrawable then
                warmthScore = warmthScore + data.warmth
                break
            end
        end
    end
    
    -- Verifica roupas frescas
    for componentId, data in pairs(Config.CoolClothing) do
        local drawable = GetPedDrawableVariation(ped, componentId)
        for _, validDrawable in ipairs(data.drawables) do
            if drawable == validDrawable then
                warmthScore = warmthScore + data.warmth
                break
            end
        end
    end

    -- Verifica se está molhado
    state.isWet = IsEntityWet(ped)
    if state.isWet then
        warmthScore = warmthScore - Config.Modifiers.WetnessColdFactor
    end
    
    state.playerWarmth = warmthScore
end

--- Aplica/Remove efeitos de tela imersivos
local function UpdateScreenEffects()
    local temp = state.currentTemperature
    local effectToApply = "none"

    if temp <= Config.ScreenEffects.Freezing.threshold then
        effectToApply = "Freezing"
    elseif temp <= Config.ScreenEffects.VeryCold.threshold then
        effectToApply = "VeryCold"
    elseif temp >= Config.ScreenEffects.Burning.threshold then
        effectToApply = "Burning"
    elseif temp >= Config.ScreenEffects.VeryHot.threshold then
        effectToApply = "VeryHot"
    end

    if state.activeScreenEffect ~= effectToApply then
        -- Limpa efeitos antigos
        SetTimecycleModifier("default")
        if Config.ScreenEffects[state.activeScreenEffect] and Config.ScreenEffects[state.activeScreenEffect].postfx then
            AnimpostfxStop(Config.ScreenEffects[state.activeScreenEffect].postfx)
        end

        -- Aplica novos efeitos
        if effectToApply ~= "none" then
            local effectData = Config.ScreenEffects[effectToApply]
            SetTimecycleModifier(effectData.timecycle)
            SetTimecycleModifierStrength(effectData.strength)
            if effectData.postfx then
                AnimpostfxPlay(effectData.postfx, effectData.postfx_duration, true)
            end
        end
        state.activeScreenEffect = effectToApply
    end
end

local function UpdateParticleEffects()
    local effectToPlay = nil
    for _, effect in ipairs(VisualEffects) do
        if state.ambientTemperature >= effect.threshold then 
            effectToPlay = effect
            break 
        end
    end
    
    if (effectToPlay and effectToPlay.name ~= activeParticleName) or (not effectToPlay and activeParticle) then
        if activeParticle then 
            StopParticleFxLooped(activeParticle, false)
            activeParticle, activeParticleName = nil, nil 
        end
        
        if effectToPlay then
            local ped = PlayerPedId()
            RequestNamedPtfxAsset(effectToPlay.dict)
            while not HasNamedPtfxAssetLoaded(effectToPlay.dict) do 
                Wait(50) 
            end
            UseParticleFxAssetNextCall(effectToPlay.dict)
            activeParticle = StartParticleFxLoopedOnPedBone(effectToPlay.name, ped, 0.0, 0.0, 0.1, 0.0, 0.0, 0.0, GetPedBoneIndex(ped, 31086), effectToPlay.scale, false, false, false)
            activeParticleName = effectToPlay.name
        end
    end
end

local function CheckExtremeTemperatureDamage(ped)
    if not Config.EnableDamage then return end
    
    local isExtreme, message = false, ""
    if state.currentTemperature <= Config.ColdDamageThreshold then
        isExtreme, message = true, "Você está morrendo de frio!"
    elseif state.currentTemperature >= Config.HotDamageThreshold then
        isExtreme, message = true, "Você está morrendo de calor!"
    end
    
    if isExtreme and GetGameTimer() > state.extremeTempTimer then
        ApplyDamageToPed(ped, Config.DamageAmount, true)
        QBCore.Functions.Notify(message, 'error', 7000)
        state.extremeTempTimer = GetGameTimer() + Config.DamageInterval
    end
end

--- FUNÇÃO PRINCIPAL DE ATUALIZAÇÃO DE TEMPERATURA
local function UpdateTemperatureLogic()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    -- 1. Determinar temperatura base do bioma
    local baseTemp = Config.DefaultTemp
    for _, zone in ipairs(ClimateZones) do
        if #(coords - zone.center) <= zone.radius then
            baseTemp = zone.baseTemp
            break
        end
    end
    
    -- 2. Aplicar modificadores de clima e hora
    local weather = GetPrevWeatherTypeHashName()
    local weatherMod = Config.Modifiers.Weather[weather] or 0.0
    
    local hour = GetClockHours()
    local timeMod = (hour >= 20 or hour <= 5) and -Config.Modifiers.NightTempDrop or 0.0

    -- 3. Calcular temperatura ambiente
    state.ambientTemperature = baseTemp + weatherMod + timeMod

    -- 4. Verificar se está abrigado
    state.isSheltered = IsPlayerSheltered(ped)
    
    -- 5. Aplicar temperatura de ambiente ou temperatura de interior
    if state.isSheltered then
        state.currentTemperature = Config.RoomTemperature
    else
        -- 6. Calcular isolamento térmico do jogador
        UpdatePlayerWarmth(ped)
        state.currentTemperature = state.ambientTemperature - state.playerWarmth
    end

    -- 7. Garantir que a temperatura está dentro de limites razoáveis
    state.currentTemperature = math.max(-30, math.min(60, state.currentTemperature))

    -- 8. Aplicar efeitos visuais e verificar danos
    UpdateScreenEffects()
    UpdateParticleEffects()
    CheckExtremeTemperatureDamage(ped)
    
    -- Debug (opcional)
    print(string.format("Temp: %.1f°C (Amb: %.1f°C | Warmth: %.1f | Weather: %s | Hour: %d | Sheltered: %s)",
        state.currentTemperature, state.ambientTemperature, state.playerWarmth, weather, hour, state.isSheltered))
end

----------------------------------------------------------------------------------------------------
-- THREADS E EVENTOS
----------------------------------------------------------------------------------------------------
CreateThread(function()
    while true do
        Wait(Config.UpdateInterval)
        if playerLoaded then
            UpdateTemperatureLogic()
        end
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    playerLoaded = true
    Wait(2000)
    UpdateTemperatureLogic()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    playerLoaded = false
    -- Limpa tudo ao deslogar
    SetTimecycleModifier("default")
    if activeParticle then StopParticleFxLooped(activeParticle, false) end
    if state.activeScreenEffect ~= "none" and Config.ScreenEffects[state.activeScreenEffect].postfx then
        AnimpostfxStop(Config.ScreenEffects[state.activeScreenEffect].postfx)
    end
end)

AddEventHandler('skinchanger:modelLoaded', function()
    if playerLoaded then
        Wait(500)
        UpdatePlayerWarmth(PlayerPedId())
    end
end)