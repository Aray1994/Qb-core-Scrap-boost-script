-----------------------------------------------------
-- CLIENT: Scrapyard + Boosting
-----------------------------------------------------

local QBCore = exports['qb-core']:GetCoreObject()
local contractVeh = nil
local contractData = nil
local lockpicked = false
local hotwired = false
local contractBlip = nil
local scrapBlips = {}
local deliveryBlip = nil

local function drawMarker(cfg)
    DrawMarker(cfg.markerType or 1, cfg.center.x, cfg.center.y, cfg.center.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        cfg.radius * 2.0, cfg.radius * 2.0, 1.0, cfg.markerColor.r, cfg.markerColor.g, cfg.markerColor.b, cfg.markerColor.a, false, true, 2, nil, nil, false)
end

local function inZone(coords, cfg)
    return #(coords - cfg.center) <= cfg.radius
end

local function deleteVehicle(entity)
    if not DoesEntityExist(entity) then return end
    NetworkRequestControlOfEntity(entity)
    local timeout = 0
    while not NetworkHasControlOfEntity(entity) and timeout < 50 do
        timeout = timeout + 1
        Wait(50)
    end
    SetEntityAsMissionEntity(entity, true, true)
    DeleteEntity(entity)
end

local function createScrapBlips()
    for _, blip in ipairs(scrapBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    scrapBlips = {}

    for _, cfg in ipairs(Config.ScrapYards) do
        local blip = AddBlipForCoord(cfg.center.x, cfg.center.y, cfg.center.z)
        SetBlipSprite(blip, Config.ScrapBlip.sprite or 365)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.ScrapBlip.scale or 0.8)
        SetBlipColour(blip, Config.ScrapBlip.color or 2)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.ScrapBlip.label or (cfg.name or "Scrapyard"))
        EndTextCommandSetBlipName(blip)
        scrapBlips[#scrapBlips + 1] = blip
    end
end

CreateThread(function()
    createScrapBlips()
end)

local function removeContractBlip()
    if contractBlip and DoesBlipExist(contractBlip) then
        RemoveBlip(contractBlip)
    end
    contractBlip = nil
end

local function removeDeliveryBlip()
    if deliveryBlip and DoesBlipExist(deliveryBlip) then
        SetBlipRoute(deliveryBlip, false)
        RemoveBlip(deliveryBlip)
    end
    deliveryBlip = nil
end

local function setScrapyardRoute()
    if #Config.ScrapYards == 0 then return end
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local nearest = Config.ScrapYards[1]
    local nearestDist = #(pos - nearest.center)
    for i = 2, #Config.ScrapYards do
        local candidate = Config.ScrapYards[i]
        local dist = #(pos - candidate.center)
        if dist < nearestDist then
            nearest = candidate
            nearestDist = dist
        end
    end

    removeDeliveryBlip()
    deliveryBlip = AddBlipForCoord(nearest.center.x, nearest.center.y, nearest.center.z)
    SetBlipSprite(deliveryBlip, Config.ScrapBlip.sprite or 365)
    SetBlipDisplay(deliveryBlip, 4)
    SetBlipScale(deliveryBlip, (Config.ScrapBlip.scale or 0.8) + 0.05)
    SetBlipColour(deliveryBlip, Config.ScrapBlip.color or 2)
    SetBlipRoute(deliveryBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString((Config.ScrapBlip.label or "Scrapyard") .. " Delivery")
    EndTextCommandSetBlipName(deliveryBlip)

    SetNewWaypoint(nearest.center.x, nearest.center.y)
    deliveryRouteSet = true
end

local function doScrap(isBoost)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return end
    if GetPedInVehicleSeat(veh, -1) ~= ped then
        return QBCore.Functions.Notify("You must be driving the vehicle to scrap it.", "error")
    end

    local plate = GetVehicleNumberPlateText(veh)
    local netId = NetworkGetNetworkIdFromEntity(veh)

    QBCore.Functions.Progressbar("scrap_vehicle", isBoost and "Scrapping boosted car..." or "Scrapping vehicle...", Config.ScrapTime, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function()
        TriggerServerEvent(isBoost and 'scrapyard:completeBoostScrap' or 'scrapyard:tryScrap', {
            plate = plate,
            netId = netId,
            isBoost = isBoost
        })
    end, function()
        QBCore.Functions.Notify("Scrapping cancelled.", "error")
    end)
end

RegisterNetEvent('scrapyard:finishScrapClient', function(netId)
    if netId then
        local veh = NetworkGetEntityFromNetworkId(netId)
        deleteVehicle(veh)
    end
    QBCore.Functions.Notify("Vehicle dismantled. Parts added to inventory.", "success")
    removeContractBlip()
    removeDeliveryBlip()
    if contractVeh then
        contractVeh = nil
        contractData = nil
        lockpicked = false
        hotwired = false
    end
end)

-----------------------------------------------------
-- Scrap yard loop
-----------------------------------------------------
CreateThread(function()
    while true do
        local wait = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        for _, cfg in ipairs(Config.ScrapYards) do
            if inZone(coords, cfg) then
                wait = 0
                drawMarker(cfg)
                if IsPedInAnyVehicle(ped, false) then
                    QBCore.Functions.DrawText3D(cfg.center.x, cfg.center.y, cfg.center.z, "[E] Scrap Vehicle")
                    if IsControlJustReleased(0, 38) then -- E
                        doScrap(contractVeh and DoesEntityExist(contractVeh))
                    end
                else
                    QBCore.Functions.DrawText3D(cfg.center.x, cfg.center.y, cfg.center.z, "Drive vehicle onto the pad")
                end
            end
        end

        Wait(wait)
    end
end)

-----------------------------------------------------
-- Illegal boosting
-----------------------------------------------------
local function spawnPed()
    local cfg = Config.BoostPed
    lib.requestModel(cfg.model)
    local ped = CreatePed(0, cfg.model, cfg.coords.x, cfg.coords.y, cfg.coords.z - 1.0, cfg.coords.w, false, true)
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)

    exports['qb-target']:AddTargetEntity(ped, {
        options = {
            {
                icon = "fa-solid fa-car-burst",
                label = "Start boosting contract",
                action = function()
                    TriggerServerEvent('scrapyard:requestContract')
                end
            }
        },
        distance = 2.0
    })
end

CreateThread(function()
    spawnPed()
end)

local function spawnContractVehicle(data)
    if contractVeh and DoesEntityExist(contractVeh) then
        deleteVehicle(contractVeh)
    end

    lib.requestModel(data.model)
    local veh = CreateVehicle(GetHashKey(data.model), data.coords.x, data.coords.y, data.coords.z, data.coords.w, true, false)
    SetVehicleNumberPlateText(veh, data.plate)
    SetVehicleDoorsLocked(veh, 2)
    SetVehicleUndriveable(veh, true)
    SetEntityAsMissionEntity(veh, true, true)
    contractVeh = veh
    contractData = data
    lockpicked = false
    hotwired = false
    removeContractBlip()
    contractBlip = AddBlipForEntity(veh)
    SetBlipSprite(contractBlip, Config.ContractBlip.sprite or 225)
    SetBlipDisplay(contractBlip, 4)
    SetBlipScale(contractBlip, Config.ContractBlip.scale or 0.9)
    SetBlipColour(contractBlip, Config.ContractBlip.color or 1)
    SetBlipAsShortRange(contractBlip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.ContractBlip.label or "Boost Vehicle")
    EndTextCommandSetBlipName(contractBlip)

    local netId = NetworkGetNetworkIdFromEntity(veh)
    TriggerServerEvent('scrapyard:registerContractVehicle', netId)

    exports['qb-target']:AddTargetEntity(veh, {
        options = {
            {
                icon = "fa-solid fa-lock-open",
                label = "Lockpick door",
                action = function(entity)
                    if lockpicked then return QBCore.Functions.Notify("Already unlocked.", "primary") end
                    TriggerServerEvent('scrapyard:useLockpick')
                end
            }
        },
        distance = 2.5
    })
end

RegisterNetEvent('scrapyard:startContract', function(data)
    QBCore.Functions.Notify("Contract received. Go steal the ride!", "success")
    spawnContractVehicle(data)
end)

RegisterNetEvent('scrapyard:lockpickSuccess', function()
    if not contractVeh or not DoesEntityExist(contractVeh) then return end
    SetVehicleDoorsLocked(contractVeh, 1)
    lockpicked = true
    QBCore.Functions.Notify("Door unlocked. Get in and hotwire it.", "primary")
end)

CreateThread(function()
    while true do
        local wait = 1000
        if contractVeh and DoesEntityExist(contractVeh) and lockpicked then
            local ped = PlayerPedId()
            if GetVehiclePedIsIn(ped, false) == contractVeh then
                wait = 0
                local pos = GetEntityCoords(contractVeh)
                QBCore.Functions.DrawText3D(pos.x, pos.y, pos.z + 1.0, "[E] Hotwire")
                if IsControlJustReleased(0, 38) and not hotwired then
                    hotwired = true
                    TriggerServerEvent('scrapyard:policeAlert', pos)
                    QBCore.Functions.Progressbar("hotwire_car", "Hotwiring...", Config.HotwireTime, false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true,
                    }, {}, {}, {}, function()
                        SetVehicleEngineOn(contractVeh, true, true, false)
                        SetVehicleUndriveable(contractVeh, false)
                        SetVehicleFixed(contractVeh)
                        SetVehicleDeformationFixed(contractVeh)
                        SetVehicleEngineHealth(contractVeh, 1000.0)
                        TriggerEvent('vehiclekeys:client:SetOwner', GetVehicleNumberPlateText(contractVeh))
                        QBCore.Functions.Notify("Hotwired! Deliver to the scrapyard.", "success")
                    end, function()
                        hotwired = false
                        QBCore.Functions.Notify("Hotwire cancelled.", "error")
                    end)
                end
            end
        end
        Wait(wait)
    end
end)
