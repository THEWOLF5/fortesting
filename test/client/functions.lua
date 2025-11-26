local core

Config.Framework = "STANDALONE"

CreateThread(function()
    Citizen.Wait(2500)
    if core == nil or Config.UseBuiltInNotifications then
        RegisterNetEvent('17mov_DrawDefaultNotification'..GetCurrentResourceName(), function(message)
            Notify(message)
        end)

        if core == nil then
            TriggerEvent("esx:getSharedObject", function(esxObject)
                core = esxObject
                Config.Framework = "ESX"
            end)

            Citizen.Wait(5000)
            if core == nil then
                InitalizeScript()
            end
        end
    end
end)

TriggerEvent("__cfx_export_qb-core_GetCoreObject", function(qbCoreObject)
    core = qbCoreObject()
    Config.Framework = "QBCore"
end)

TriggerEvent("__cfx_export_es_extended_getSharedObject", function(esxObject)
    core = esxObject()
    Config.Framework = "ESX"
end)

function GetPlayerData()
    if Config.Framework == "QBCore" then
        return core.Functions.GetPlayerData()
    elseif Config.Framework == "ESX" then
        return core.GetPlayerData()
    else
        return {job = {name = "unknown", grade = 0}}
    end
end

function IsDead(ped)
    return GetEntityHealth(ped) == 0
end

function DeleteVehicleByCore(vehicleEntity)
    if Config.Framework == "QBCore" then
        core.Functions.DeleteVehicle(vehicleEntity)
    elseif Config.Framework == "ESX" then
        core.Game.DeleteVehicle(vehicleEntity)
    else
        SetEntityAsMissionEntity(vehicleEntity, false, true)
        DeleteVehicle(vehicleEntity)
    end
end

function Notify(message)
    if Config.UseBuiltInNotifications and Config.useModernUI then
        local notificationType = "good"
        if CheckIfNotificationIsWrong(message) then
            notificationType = "wrong"
        end

        SendNUIMessage({
            action = "showNotification",
            type = notificationType,
            msg = message
        })
    else
        if Config.Framework == "QBCore" then
            core.Functions.Notify(message)
        elseif Config.Framework == "ESX" then
            core.ShowNotification(message)
        else
            SetNotificationTextEntry('STRING')
            AddTextComponentString(message)
            DrawNotification(false, true)
        end
    end
end

local vehicleModel, vehiclePlate, currentVehicle
function SetVehicle(selectedVehicle)
    currentVehicle = selectedVehicle
    vehicleModel = GetDisplayNameFromVehicleModel(GetEntityModel(currentVehicle))
    vehiclePlate = GetVehicleNumberPlateText(currentVehicle)

    -- Keys Systems
    if GetResourceState("qs-vehiclekeys") == "started" then
        exports["qs-vehiclekeys"]:GiveKeys(vehiclePlate, vehicleModel, true)
    end

    TriggerEvent('cd_garage:AddKeys', vehiclePlate)
    TriggerServerEvent("vehicles_keys:selfGiveVehicleKeys", vehiclePlate)
    TriggerEvent("vehiclekeys:client:SetOwner", vehiclePlate)

    -- Fuel systems
    if GetResourceState("LegacyFuel") == "started" then
        exports["LegacyFuel"]:SetFuel(currentVehicle, 100.0)
    end

    if GetResourceState("cdn-fuel") == "started" then
function SetVehicleFuel(vehicle)
    if GetResourceState("cdn-fuel") == "started" then
        exports["cdn-fuel"]:SetFuel(vehicle, 100.0)
    end

    if GetResourceState("ps-fuel") == "started" then
        exports["ps-fuel"]:SetFuel(vehicle, 100.0)
    end

    Entity(vehicle).state.fuel = 100.0
end

function RemoveVehicleKeys(plate, model)
    if GetResourceState("qs-vehiclekeys") == "started" then
        exports["qs-vehiclekeys"]:RemoveKeys(plate, model)
    end
end

function PrepareVehicleForSpawn()
    -- Before Vehicle spawn
end

function DrawText3D(x, y, z, text)
    local onScreen, screenX, screenY = World3dToScreen2d(x, y, z)
    SetTextScale(0.32, 0.32)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 255)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    DrawText(screenX, screenY)
    local factor = (string.len(text)) / 500
    DrawRect(screenX, screenY + 0.0125, 0.030 + factor, 0.03, 0, 0, 0, 150)
end

function ShowHelpNotification(message)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

function ChangeClothes(clothingType)
    if Config.Framework ~= "QBCore" and Config.Framework ~= "ESX" then
        return print("CANNOT CHANGE CLOTHES, PLEASE CONFIGURE UR CLOTHES SYSTEM IN /Client/Functions.lua file.")
    end

    RequestAnimDict("clothingshirt")
    while not HasAnimDictLoaded("clothingshirt") do Citizen.Wait(0) end

    local playerPed = PlayerPedId()
    TaskPlayAnim(playerPed, "clothingshirt", "try_shirt_positive_d", 8.0, 1.0, -1, 49, 0, false, false, false)
    Citizen.Wait(1000)
    if clothingType == "work" then
        if GetEntityModel(PlayerPedId()) == 1885233650 then
            for _, clothingItem in pairs(Config.realClothes.male) do
                SetPedComponentVariation(playerPed, clothingItem["component_id"], clothingItem["drawable"], clothingItem["texture"], 0)
            end
            SetPedPropIndex(playerPed, 0, Config.Clothes.maleHelmet.clotheId, Config.Clothes.maleHelmet.variation, true)
        else
            for _, clothingItem in pairs(Config.realClothes.female) do
                SetPedComponentVariation(playerPed, clothingItem["component_id"], clothingItem["drawable"], clothingItem["texture"], 0)
            end
            SetPedPropIndex(playerPed, 0, Config.Clothes.femaleHelmet.clotheId, Config.Clothes.femaleHelmet.variation, true)
        end
    else
        if Config.Framework == "QBCore" then
            TriggerServerEvent('qb-clothes:loadPlayerSkin')
        elseif Config.Framework == "ESX" then
            Core.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
                TriggerEvent('skinchanger:loadSkin', skin)
            end)
        end

        TriggerEvent("fivem-appearance:client:reloadSkin")
        TriggerEvent("fivem-appearance:ReloadSkin")
        TriggerEvent("illenium-appearance:client:reloadSkin")
        TriggerEvent("illenium-appearance:ReloadSkin")
    end

    Citizen.Wait(1000)
    ClearPedTasks(playerPed)
end

function CheckIfNotificationIsWrong(text)
    -- Function body (implementation not provided in original code)
end
-- Fonction pour vérifier si une notification d'erreur spécifique doit être affichée
local function shouldDisplayErrorNotification(text)
    local arrayName = nil
    for key, value in pairs(Config.Lang) do
        if value == text then
            arrayName = key
            break
        end
    end

    return Config.WrongNotifications[arrayName] or false
end

-- Configuration des notifications d'erreur à ne pas afficher
Config.WrongNotifications = {
    ["no_permission"] = true,
    ["too_far"] = true,
    ["alreadyWorking"] = true,
    ["wrongCar"] = true,
    ["CarNeeded"] = true,
    ["nobodyNearby"] = true,
    ["cantInvite"] = true,
    ["spawnpointOccupied"] = true,
    ["pipesNotReady"] = true,
    ["workstationOccupied"] = true,
    ["notFullJob"] = true,
    ["notADriver"] = true,
    ["partyIsFull"] = true,
    ["wrongReward1"] = true,
    ["wrongReward2"] = true,
    ["isAlreadyHost"] = true,
    ["isBusy"] = true,
    ["hasActiveInvite"] = true,
    ["HaveActiveInvite"] = true,
    ["InviteDeclined"] = true,
    ["error"] = true,
    ["kickedOut"] = true,
    ["RequireOneFriend"] = true,
    ["clientsPenalty"] = true,
    ["noMixerStatus"] = true,
    ["dontHaveReqItem"] = true,
    ["notEverybodyHasRequiredJob"] = true,
}

-- Configuration des vêtements réels (convertis)
Config.realClothes = {
    male = {},
    female = {},
}

-- Traduction des identifiants de composants de vêtements
local componentIdTranslation = {
    ["mask"] = 1,
    ["arms"] = 3,
    ["pants"] = 4,
    ["bag"] = 5,
    ["shoes"] = 6,
    ["t-shirt"] = 8,
    ["torso"] = 11,
    ["decals"] = 10,
    ["kevlar"] = 9,
}

-- Conversion des vêtements masculins
for clothingKey, clothingValue in pairs(Config.Clothes.male) do
    table.insert(Config.realClothes.male, {component_id = componentIdTranslation[clothingKey], drawable = clothingValue.clotheId, texture = clothingValue.variation})
end

-- Conversion des vêtements féminins
for clothingKey, clothingValue in pairs(Config.Clothes.female) do
    table.insert(Config.realClothes.female, {component_id = componentIdTranslation[clothingKey], drawable = clothingValue.clotheId, texture = clothingValue.variation})
end