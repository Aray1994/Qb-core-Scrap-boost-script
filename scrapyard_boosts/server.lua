-----------------------------------------------------
-- SERVER: Scrapyard + Boosting
-----------------------------------------------------

local QBCore = exports['qb-core']:GetCoreObject()
local activeContracts = {}
local lastContractTime = {}

local function giveScrapRewards(src, isBoost)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local multiplier = isBoost and Config.BoostPayoutMultiplier or 1.0

    for _, reward in ipairs(Config.ScrapRewards) do
        local amount = math.random(reward.min, reward.max)
        amount = math.floor(amount * multiplier)
        Player.Functions.AddItem(reward.item, amount)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[reward.item], 'add', amount)
    end

    -- Force persist inventory so rewards are written to the database promptly
    Player.Functions.Save()
end

-- Check if a vehicle plate is owned
local function isOwnedPlate(plate, cb)
    if not Config.BlockOwnedVehicles then return cb(false) end
    exports.oxmysql:scalar('SELECT 1 FROM player_vehicles WHERE plate = ? LIMIT 1', {plate}, function(result)
        cb(result ~= nil)
    end)
end

RegisterNetEvent('scrapyard:tryScrap', function(data)
    local src = source
    local plate = data.plate and data.plate:gsub("%s+", "") or ''
    isOwnedPlate(plate, function(owned)
        if owned then
            TriggerClientEvent('QBCore:Notify', src, "This vehicle is registered and cannot be scrapped.", 'error')
            return
        end

        giveScrapRewards(src, data.isBoost)
        TriggerClientEvent('scrapyard:finishScrapClient', src, data.netId)
    end)
end)

-----------------------------------------------------
-- Boosting contracts
-----------------------------------------------------

RegisterNetEvent('scrapyard:requestContract', function()
    local src = source
    if activeContracts[src] then
        return TriggerClientEvent('QBCore:Notify', src, "Finish your current contract first.", 'error')
    end

    local now = os.time()
    local cooldown = Config.ContractCooldown or 0
    if cooldown > 0 and lastContractTime[src] and (now - lastContractTime[src]) < cooldown then
        local remaining = cooldown - (now - lastContractTime[src])
        local minutes = math.ceil(remaining / 60)
        return TriggerClientEvent('QBCore:Notify', src, ("Come back in %d minute(s) for another boost."):format(minutes), 'error')
    end

    local spot = Config.BoostSpawns[math.random(1, #Config.BoostSpawns)]
    local model = Config.BoostVehicles[math.random(1, #Config.BoostVehicles)]
    local plate = ("BST%s"):format(math.random(10000, 99999))

    activeContracts[src] = {
        model = model,
        plate = plate,
        netId = nil
    }

    TriggerClientEvent('scrapyard:startContract', src, {
        coords = spot.coords,
        model = model,
        plate = plate
    })

    lastContractTime[src] = now
end)

RegisterNetEvent('scrapyard:registerContractVehicle', function(netId)
    local src = source
    if activeContracts[src] then
        activeContracts[src].netId = netId
    end
end)

RegisterNetEvent('scrapyard:useLockpick', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if not Player.Functions.RemoveItem(Config.LockpickItem, 1) then
        TriggerClientEvent('QBCore:Notify', src, "You need a lockpick.", 'error')
        return
    end
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.LockpickItem], 'remove', 1)
    TriggerClientEvent('scrapyard:lockpickSuccess', src)
end)

RegisterNetEvent('scrapyard:policeAlert', function(coords)
    if not Config.SendPoliceAlert then return end
    TriggerClientEvent('police:client:policeAlert', -1, coords, Config.AlertMessage or "Vehicle hotwire in progress")
end)

RegisterNetEvent('scrapyard:completeBoostScrap', function(data)
    local src = source
    local contract = activeContracts[src]
    if not contract or not contract.netId then
        return TriggerClientEvent('QBCore:Notify', src, "No active boosting contract.", 'error')
    end

    if data and data.netId and data.netId ~= contract.netId then
        return TriggerClientEvent('QBCore:Notify', src, "Wrong vehicle for this contract.", 'error')
    end

    giveScrapRewards(src, true)
    TriggerClientEvent('scrapyard:finishScrapClient', src, contract.netId)
    activeContracts[src] = nil
end)

AddEventHandler('playerDropped', function()
    activeContracts[source] = nil
    lastContractTime[source] = nil
end)
