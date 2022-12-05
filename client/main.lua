local QBCore = exports['qb-core']:GetCoreObject()
local targets = {}
local showering = false

CreateThread(function()
    for i=1, #Config.Locations do
        local shower = Config.Locations[i]
        local coords = shower.coords
        local spherename = ("Shower_%s"):format(i)
        if Config.Framework == 'QB' then
            targets[spherename] = exports['qb-target']:AddCircleZone(spherename, coords, 0.6, {
                name = spherename,
                useZ = true,
                }, {
                    options = {
                        {
                            type = "client",
                            event = 'serrulata-shower:client:takeShower',
                            icon = 'fas fa-shower',
                            label = 'Take Shower',
                            canInteract = function(entity, distance, coords, name)
                                return not showering and distance < 1
                            end
                        },
                    },
                distance = 1.5
            })
        elseif Config.Framework == 'OX' then
            local radius = Config.Locations[i].radius
            exports.ox_target:addSphereZone({
                coords = coords,
                radius = radius,
                options = {
                    {
                        name = spherename,
                        icon = 'fas fa-shower',
                        label = 'Take Shower',
                        onSelect = function()
                            TriggerEvent('serrulata-shower:client:takeShower')
                        end,
                        canInteract = function(entity, distance, coords, name)
                            return not showering and distance < 1
                        end
                    },
                }
            })
        end
    end
end)
RegisterNetEvent('serrulata-shower:client:takeShower', function()
    local sex = 'male'
    local PlayerPed = PlayerPedId()
    if GetEntityModel(PlayerPed) == -1667301416 then
        sex = 'female'
    else
        sex = 'male'
    end
    if not showering then
        showering = true
        FreezeEntityPosition((PlayerPedId()), true)
        local coords = GetEntityCoords(PlayerPedId())
        ProgressBar(sex)
        while showering do
            if not HasNamedPtfxAssetLoaded("core") then
                RequestNamedPtfxAsset("core")
                while not HasNamedPtfxAssetLoaded("core") do
                    Wait(1)
                end
            end
            UseParticleFxAssetNextCall("core")
            particles  = StartParticleFxLoopedAtCoord("ent_sht_water", coords.x, coords.y, coords.z +1.2, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
            UseParticleFxAssetNextCall("core")
            Wait(3000)
        end
    end
end)

function ProgressBar(sex)
    local animDict = sex == "male" and "anim@mp_yacht@shower@male@" or "anim@mp_yacht@shower@female@"
    local anim = sex == "male" and "male_shower_enter_into_idle" or "shower_enter_into_idle"
    if showering then
        if Config.Framework == 'QB' then
            QBCore.Functions.Progressbar("shower", "Taking a shower", 9000, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {
                animDict = animDict,
                anim = anim,
                flags = 16,
            }, {}, {}, function() -- Done
                FreezeEntityPosition((PlayerPedId()), false)
                ClearPedTasksImmediately(PlayerPedId())
                StopParticleFxLooped(particles, false)
                TriggerServerEvent('hud:server:RelieveStress', 25)
                showering = false
            end, function() -- Cancel
                FreezeEntityPosition((PlayerPedId()), false)
                ClearPedTasksImmediately(PlayerPedId())
                StopParticleFxLooped(particles, false)
                showering = false
            end)
        elseif Config.Framework == 'OX' then
            if lib.progressBar({
                duration = 9000,
                label = 'Taking a shower',
                useWhileDead = false,
                canCancel = true,
                disable = {
                    move = true,
                    car = true,
                    combat = true
                },
                anim = {
                    dict = animDict,
                    clip = anim,
                    flag = 16
                }
            }) then
                FreezeEntityPosition((PlayerPedId()), false)
                ClearPedTasksImmediately(PlayerPedId())
                StopParticleFxLooped(particles, false)
                TriggerServerEvent('hud:server:RelieveStress', 25)
                showering = false
            else
                FreezeEntityPosition((PlayerPedId()), false)
                ClearPedTasksImmediately(PlayerPedId())
                StopParticleFxLooped(particles, false)
                showering = false
            end
        end
    end
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler('onResourceStart', function(resource) if resource ~= GetCurrentResourceName() then return end
    print('Serrulata-Shower started')
end)

AddEventHandler('onResourceStop', function(resource) if resource ~= GetCurrentResourceName() then return end
    if Config.Framework == 'QB' then
        for k, v in pairs(targets) do
            exports['qb-target']:RemoveZone(k)
        end
        print('Serrulata-Shower stopped')
    elseif Config.Framework == 'OX' then
        print('Serrulata-Shower stopped')
    end
end)
