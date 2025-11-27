-- Deobfuscated and improved by Jules

local core = nil

-- =================================================================================================
-- FRAMEWORK INITIALIZATION
-- =================================================================================================

CreateThread(function()
    if exports['qb-core'] then
        core = exports['qb-core']:GetCoreObject()
        if core then
            Config.Framework = "QBCore"
            print("[17mov_construction] Framework detected: QBCore")
            return
        end
    end

    if exports['es_extended'] then
        core = exports['es_extended']:getSharedObject()
        if core then
            Config.Framework = "ESX"
            print("[17mov_construction] Framework detected: ESX")
            return
        end
    end

    -- Fallback for older ESX or custom setups
    TriggerEvent("esx:getSharedObject", function(esxObject)
        if esxObject then
            core = esxObject
            Config.Framework = "ESX"
            print("[17mov_construction] Framework detected: ESX (Fallback)")
        end
    end)
end)

-- =================================================================================================
-- FRAMEWORK ABSTRACTION LAYER
-- =================================================================================================

local cachedNames = {}

-- Returns the character's full name based on the framework.
function GetPlayerIdentity(playerId)
    if cachedNames[playerId] then
        return cachedNames[playerId]
    end

    local identity = "Unknown Player"
    if Config.Framework == "QBCore" then
        local qbPlayer = core.Functions.GetPlayer(playerId)
        if qbPlayer and qbPlayer.PlayerData and qbPlayer.PlayerData.charinfo then
            identity = qbPlayer.PlayerData.charinfo.firstname .. " " .. qbPlayer.PlayerData.charinfo.lastname
        end
    elseif Config.Framework == "ESX" then
        local esxPlayer = core.GetPlayerFromId(playerId)
        if esxPlayer then
            identity = esxPlayer.getName()
        end
    else
        identity = GetPlayerName(tostring(playerId))
    end
    cachedNames[playerId] = identity
    return identity
end

-- Sends a notification to the player using the framework's system.
function Notify(playerId, message)
    if not playerId then return end
    if Config.Framework == "QBCore" then
        TriggerClientEvent("QBCore:Notify", playerId, message, "primary", 5000)
    elseif Config.Framework == "ESX" then
        TriggerClientEvent("esx:showNotification", playerId, message)
    else
        TriggerClientEvent("17mov_DrawDefaultNotification", playerId, message)
    end
end

-- Handles payment and item rewards for completing a job.
function Pay(playerId, amount, jobProgress)
    if not playerId or not amount or not jobProgress then return end

    local itemsToGiveCount = math.floor(jobProgress)

    if Config.Framework == "QBCore" then
        local player = core.Functions.GetPlayer(playerId)
        if player then
            player.Functions.AddMoney("cash", amount)

            local itemsToAdd = {}
            for i = 1, itemsToGiveCount do
                for _, item in pairs(Config.RewardItemsToGive) do
                    if math.random(100) <= item.chance and jobProgress >= item.minimumProgressPercent then
                        itemsToAdd[item.item_name] = (itemsToAdd[item.item_name] or 0) + item.amount
                    end
                end
            end
            for itemName, itemCount in pairs(itemsToAdd) do
                player.Functions.AddItem(itemName, itemCount)
            end
        end
    elseif Config.Framework == "ESX" then
        local player = core.GetPlayerFromId(playerId)
        if player then
            player.addMoney(amount)
            local itemsToAdd = {}
            for i = 1, itemsToGiveCount do
                for _, item in pairs(Config.RewardItemsToGive) do
                    if math.random(100) <= item.chance and jobProgress >= item.minimumProgressPercent then
                         itemsToAdd[item.item_name] = (itemsToAdd[item.item_name] or 0) + item.amount
                    end
                end
            end
            for itemName, itemCount in pairs(itemsToAdd) do
                player.addInventoryItem(itemName, itemCount)
            end
        end
    else
        print(string.format("Standalone: Paid player %d $%d and would have given items based on progress %d", playerId, amount, jobProgress))
    end
end

-- Removes money from a player as a penalty.
function PayPenalty(playerId, amount)
    if not playerId or not amount then return end

    if Config.Framework == "QBCore" then
        local player = core.Functions.GetPlayer(playerId)
        if player then
            player.Functions.RemoveMoney("cash", amount)
        end
    elseif Config.Framework == "ESX" then
        local player = core.GetPlayerFromId(playerId)
        if player then
            player.removeMoney(amount)
        end
    else
        print(string.format("Standalone: Charged player %d a penalty of $%d", playerId, amount))
    end
end

-- Checks if a player has the required item to start a job.
function IsHaveRequiredItem(playerId)
    if Config.RequiredItem.name == "none" then
        return true
    end

    if Config.Framework == "QBCore" then
        local player = core.Functions.GetPlayer(playerId)
        if player then
            local item = player.Functions.GetItemByName(Config.RequiredItem.name)
            return item and item.amount >= Config.RequiredItem.amount
        end
    elseif Config.Framework == "ESX" then
        local player = core.GetPlayerFromId(playerId)
        if player then
            local item = player.getInventoryItem(Config.RequiredItem.name)
            return item and item.count >= Config.RequiredItem.amount
        end
    end
    return false
end

-- Returns the player's job name.
function GetPlayerJob(playerId)
    if not playerId then return "unemployed" end

    if Config.Framework == "QBCore" then
        local player = core.Functions.GetPlayer(playerId)
        if player and player.PlayerData.job then
            return player.PlayerData.job.name
        end
    elseif Config.Framework == "ESX" then
        local player = core.GetPlayerFromId(playerId)
        if player and player.job then
            return player.job.name
        end
    end
    return "unemployed"
end
