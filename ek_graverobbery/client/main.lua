local cooldowns = {}

CreateThread(function()
    for k, grave in pairs(Config.Graves) do
        exports.ox_target:addSphereZone({
            coords = grave.coords,
            radius = grave.distance,
            options = {
                {
                    name = 'grave_robbery_' .. k,
                    icon = grave.icon,
                    label = grave.label,
                    onSelect = function()
                        if cooldowns[k] then
                            local remaining = math.ceil(cooldowns[k] - GetGameTimer() / 1000)
                            lib.notify({
                                title = _U('notify_title'),
                                description = _U('dug_grave'),
                                type = 'error'
                            })
                            return
                        end
                        StartDigging(k, grave)
                    end
                }
            }
        })
    end
end)

function HasShovel(cb)
    ESX.TriggerServerCallback('ek_graverobbery:hasItem', function(has)
        cb(has)
    end, Config.RequiredItem)
end

function CreateShovelProp()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    
    local shovel1Hash = GetHashKey('prop_tool_shovel')
    local shovel2Hash = GetHashKey('prop_ld_shovel_dirt')
    
    RequestModel(shovel1Hash)
    RequestModel(shovel2Hash)
    
    while not HasModelLoaded(shovel1Hash) or not HasModelLoaded(shovel2Hash) do
        Wait(100)
    end
    
    local shovel1 = CreateObject(shovel1Hash, coords.x, coords.y, coords.z, true, true, false)
    local shovel2 = CreateObject(shovel2Hash, coords.x, coords.y, coords.z, true, true, false)
    
    AttachEntityToEntity(
        shovel1,
        playerPed,
        GetPedBoneIndex(playerPed, 28422),
        0.0, 0.0, 0.24,
        0.0, 0.0, 0.0,
        true, true, false, true, 1, true
    )
    
    AttachEntityToEntity(
        shovel2,
        playerPed,
        GetPedBoneIndex(playerPed, 28422),
        0.0, 0.0, 0.24,
        0.0, 0.0, 0.0,
        true, true, false, true, 1, true
    )
    
    return {shovel1, shovel2}
end

function LoadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(100)
    end
end

function StartDigging(graveId, grave)
    HasShovel(function(hasShovel)
        if not hasShovel then
            lib.notify({
                title = _U('notify_title'),
                description = _U('no_shovel'),
                type = 'error'
            })
            return
        end
        
        local playerPed = PlayerPedId()
        
        local shovels = CreateShovelProp()
        
        LoadAnimDict('random@burial')
        
        TaskPlayAnim(playerPed, 'random@burial', 'a_burial', 8.0, -8.0, -1, 1, 0, false, false, false)
        
        if lib.progressBar({
            duration = Config.DiggingTime,
            label = _U('progressbar_digging'),
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
                move = true,
                combat = true,
            },
        }) then
            ClearPedTasks(playerPed)
            for _, shovel in ipairs(shovels) do
                DeleteObject(shovel)
            end
            
            cooldowns[graveId] = GetGameTimer() / 1000 + grave.cooldown
            
            SetTimeout(grave.cooldown * 1000, function()
                cooldowns[graveId] = nil
            end)
            
            TriggerServerEvent('ek_graverobbery:digGrave', graveId)
            
        else
            ClearPedTasks(playerPed)
            for _, shovel in ipairs(shovels) do
                DeleteObject(shovel)
            end
            
            lib.notify({
                title = _U('notify_title'),
                description = _U('digging_cancelled'),
                type = 'error'
            })
        end
    end)
end

RegisterNetEvent('ek_graverobbery:syncCooldown')
AddEventHandler('ek_graverobbery:syncCooldown', function(graveId, remainingTime)
    if remainingTime > 0 then
        cooldowns[graveId] = GetGameTimer() / 1000 + remainingTime
        
        SetTimeout(remainingTime * 1000, function()
            cooldowns[graveId] = nil
        end)
    end
end)
