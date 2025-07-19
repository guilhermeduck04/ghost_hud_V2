RegisterCommand('togglehud', function()
    TriggerEvent('ghost-hud:forceOpenConfig')
end, false)

RegisterNetEvent('ghost-hud:forceOpenConfig')
AddEventHandler('ghost-hud:forceOpenConfig', function()
    SendNUIMessage({
        action = 'forceShowConfig'
    })
    SetNuiFocus(true, true)
end)