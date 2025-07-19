local Config = {
    hudEnabled = true,
    showValues = false,
    minimapEnabled = true,
    elements = {
        health = { enabled = true },
        armor = { enabled = true },
        hunger = { enabled = true },
        thirst = { enabled = true },
        stamina = { enabled = true },
        voice = { enabled = true },
        vehicle = { enabled = true },
        weapon = { enabled = true },
        clock = { enabled = true },
        money = { enabled = true },
        job = { enabled = true },
        id = { enabled = true },
        radiation = { enabled = true },
        stress = { enabled = true },
        temperature = { enabled = true },
        hudImage = { enabled = true }
    },
    positions = {
        left = { x = '30px', y = 'bottom: 30px' },
        right = { x = 'calc(100% - 30px)', y = 'bottom: 30px' },
        top = { x = '50%', y = 'top: 20px' }
    }
}

Config.Zones = {
    ["Sandy Shores"] = { center = vector3(1853.0, 3687.0, 34.0), radius = 1000.0, baseTemp = 36 },
    ["Paleto Bay"] = { center = vector3(-135.0, 6450.0, 30.0), radius = 800.0, baseTemp = 22 },
    ["Mount Chiliad"] = { center = vector3(501.0, 5593.0, 800.0), radius = 1500.0, baseTemp = 5 },
    ["City"] = { center = vector3(200.0, -900.0, 30.0), radius = 1500.0, baseTemp = 28 },
    ["Ocean"] = { center = vector3(-1600.0, -2600.0, 0.0), radius = 2500.0, baseTemp = 18 },
    ["Vinewood Hills"] = { center = vector3(-500.0, 1000.0, 150.0), radius = 1200.0, baseTemp = 20 }
}

Config.AltitudeEffect = {
    threshold = 200.0, -- metros
    multiplier = 0.02  -- quanto maior, mais frio
}


local function OpenHUDConfig()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openConfig",
        config = Config
    })
end

RegisterCommand('hudconfig', function()
    OpenHUDConfig()
end, false)

RegisterNUICallback('saveConfig', function(data, cb)
    Config = data.config
    TriggerEvent('ghost-hud:updateConfig', Config)
    cb({})
end)

RegisterNUICallback('closeConfig', function(_, cb)
    SetNuiFocus(false, false)
    cb({})
end)