local playerCooldowns = {}
local playerDigCount = {}
local playerLastDig = {}

local function SendWebhook(webhook, data)
    if webhook == '' then return end
    
    PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({
        username = WebhookConfig.BotName,
        avatar_url = WebhookConfig.BotAvatar,
        embeds = data
    }), {['Content-Type'] = 'application/json'})
end

local function KickPlayer(source, reason)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    SendWebhook(WebhookConfig.AntiCheatWebhook, {{
        title = 'AntiCheat - Player Kicked',
        description = string.format('**Player:** %s\n**Identifier:** %s\n**Reason:** %s', xPlayer.getName(), xPlayer.identifier, reason),
        color = WebhookConfig.Colors.kick,
        timestamp = os.date('!%Y-%m-%dT%H:%M:%S')
    }})
    
    DropPlayer(source, 'AntiCheat: ' .. reason)
end

local playerDigStartTime = {}

local function CheckAntiCheat(source)
    if not Config.AntiCheat.Enabled then
        return true
    end
    
    if not playerDigCount[source] then
        playerDigCount[source] = 0
        playerLastDig[source] = 0
        playerDigStartTime[source] = 0
    end
    
    local currentTime = os.time()
    local timeSinceLastDigStart = currentTime - playerDigStartTime[source]
    
    if timeSinceLastDigStart < Config.AntiCheat.MinTimeBetweenDigs and playerDigStartTime[source] > 0 then
        KickPlayer(source, 'Suspicious digging speed detected')
        return false
    end
    
    playerDigStartTime[source] = currentTime
    playerDigCount[source] = playerDigCount[source] + 1
    playerLastDig[source] = currentTime
    
    if playerDigCount[source] > Config.AntiCheat.MaxDigsInTimeFrame then
        local firstDigTime = currentTime - (playerDigCount[source] - 1) * Config.AntiCheat.MinTimeBetweenDigs
        local timeFrame = currentTime - firstDigTime
        
        if timeFrame < Config.AntiCheat.TimeFrameSeconds then
            KickPlayer(source, 'Too many dig attempts in short time')
            return false
        end
        playerDigCount[source] = 0
    end
    
    return true
end

ESX.RegisterServerCallback('ek_graverobbery:hasItem', function(source, cb, item)
    local xPlayer = ESX.GetPlayerFromId(source)
    local hasItem = xPlayer.getInventoryItem(item).count > 0
    cb(hasItem)
end)

function GenerateLoot()
    local lootTable = {}
    local itemCount = math.random(Config.MinLootItems, Config.MaxLootItems)
    
    for i = 1, itemCount do
        local roll = math.random(1, 100)
        local cumulativeChance = 0
        
        for _, loot in ipairs(Config.Loot) do
            cumulativeChance = cumulativeChance + loot.chance
            
            if roll <= cumulativeChance then
                local amount = math.random(loot.min, loot.max)
                table.insert(lootTable, {
                    item = loot.item,
                    label = loot.label,
                    amount = amount
                })
                break
            end
        end
    end
    
    return lootTable
end

RegisterNetEvent('ek_graverobbery:digGrave')
AddEventHandler('ek_graverobbery:digGrave', function(graveId)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    
    if not xPlayer then return end
    
    if not CheckAntiCheat(_source) then
        return
    end
    
    local identifier = xPlayer.identifier
    local currentTime = os.time()
    
    if not playerCooldowns[identifier] then
        playerCooldowns[identifier] = {}
    end
    
    if playerCooldowns[identifier][graveId] and currentTime < playerCooldowns[identifier][graveId] then
        KickPlayer(_source, 'Bypass cooldown attempt detected')
        return
    end
    
    local shovel = xPlayer.getInventoryItem(Config.RequiredItem)
    if not shovel or shovel.count < 1 then
        KickPlayer(_source, 'Digging without shovel - possible exploit')
        return
    end
    
    local grave = Config.Graves[graveId]
    if not grave then 
        KickPlayer(_source, 'Invalid grave ID - possible exploit')
        return 
    end
    
    playerCooldowns[identifier][graveId] = currentTime + grave.cooldown
    
    local loot = GenerateLoot()
    
    if #loot == 0 then
        TriggerClientEvent('ox_lib:notify', _source, {
            title = _U('notify_title'),
            description = _U('found_nothing'),
            type = 'info'
        })
        return
    end
    
    local itemsAdded = {}
    local inventoryFull = false
    
    for _, reward in ipairs(loot) do
        if exports.ox_inventory then
            local success = exports.ox_inventory:AddItem(_source, reward.item, reward.amount)
            
            if success then
                table.insert(itemsAdded, string.format('%sx %s', reward.amount, reward.label))
            else
                inventoryFull = true
            end
        else
            local canCarry = xPlayer.canCarryItem(reward.item, reward.amount)
            
            if canCarry then
                xPlayer.addInventoryItem(reward.item, reward.amount)
                table.insert(itemsAdded, string.format('%sx %s', reward.amount, reward.label))
            else
                inventoryFull = true
            end
        end
    end
    
    if #itemsAdded > 0 then
        local itemsList = table.concat(itemsAdded, '\n')
        TriggerClientEvent('ox_lib:notify', _source, {
            title = _U('notify_title'),
            description = _U('received_items', itemsList),
            type = 'success',
            duration = 5000
        })
        
        local lootDescription = ''
        for _, item in ipairs(itemsAdded) do
            lootDescription = lootDescription .. '- ' .. item .. '\n'
        end
        
        SendWebhook(WebhookConfig.LootWebhook, {{
            title = 'Grave Robbery - Loot Received',
            description = string.format('**Player:** %s\n**Identifier:** %s\n**Grave:** %s\n**Items:**\n%s', 
                xPlayer.getName(), 
                xPlayer.identifier, 
                grave.label,
                lootDescription
            ),
            color = WebhookConfig.Colors.loot,
            timestamp = os.date('!%Y-%m-%dT%H:%M:%S')
        }})
        
        local logMessage = string.format('%s [%s] dug grave %s and received:', xPlayer.getName(), xPlayer.identifier, graveId)
        for _, item in ipairs(itemsAdded) do
            logMessage = logMessage .. string.format('\n- %s', item)
        end
        print(logMessage)
    end
    
    if inventoryFull then
        TriggerClientEvent('ox_lib:notify', _source, {
            title = _U('notify_title'),
            description = _U('inventory_full'),
            type = 'error'
        })
    end
end)

AddEventHandler('playerConnecting', function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    
    if xPlayer then
        local identifier = xPlayer.identifier
        local currentTime = os.time()
        
        if playerCooldowns[identifier] then
            for graveId, cooldownEnd in pairs(playerCooldowns[identifier]) do
                if currentTime < cooldownEnd then
                    local remaining = cooldownEnd - currentTime
                    TriggerClientEvent('ek_graverobbery:syncCooldown', _source, graveId, remaining)
                end
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    local _source = source
    if playerDigCount[_source] then
        playerDigCount[_source] = nil
        playerLastDig[_source] = nil
        playerDigStartTime[_source] = nil
    end
end)

CreateThread(function()
    while true do
        Wait(3600000)
        
        local currentTime = os.time()
        for identifier, graves in pairs(playerCooldowns) do
            for graveId, cooldownEnd in pairs(graves) do
                if currentTime >= cooldownEnd then
                    playerCooldowns[identifier][graveId] = nil
                end
            end
        end
    end
end)
