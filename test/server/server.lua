-- Deobfuscated and improved by Jules

-- Framework Integration
local QBCore = exports['qb-core']:GetCoreObject()

-- Global Variables
local teams = {}
local pendingInvites = {}
local jobCooldowns = {}
local lastTaskCompletionTime = {}

-- =================================================================================================
-- CALLBACKS
-- =================================================================================================

local Callbacks = {}

RegisterNetEvent("17mov_Callbacks:GetResponse", function(eventName, cbId, ...)
    local src = source
    if Callbacks[eventName] then
        Callbacks[eventName](src, function(...)
            TriggerClientEvent("17mov_Callbacks:receiveData", src, eventName, cbId, ...)
        end, ...)
    end
end)

function RegisterServerCallback(eventName, cb)
    Callbacks[eventName] = cb
end


-- =================================================================================================
-- CORE LOGIC
-- =================================================================================================

function getTeamByHost(hostId)
    for _, team in pairs(teams) do
        if team.host == hostId then
            return team
        end
    end
    return nil
end

function getTeamByMember(memberId)
    for _, team in pairs(teams) do
        if team.host == memberId then
            return team
        end
        for _, client in ipairs(team.clients) do
            if client == memberId then
                return team
            end
        end
    end
    return nil
end

function getPlayerName(playerId)
    return QBCore.Functions.GetPlayer(playerId).PlayerData.charinfo.firstname .. " " .. QBCore.Functions.GetPlayer(playerId).PlayerData.charinfo.lastname
end

function notify(playerId, msg)
    TriggerClientEvent('QBCore:Notify', playerId, msg, 'primary', 5000)
end

function triggerForAllMembers(hostId, eventName, ...)
    local team = getTeamByHost(hostId)
    if team then
        TriggerClientEvent(eventName, team.host, ...)
        for _, clientId in ipairs(team.clients) do
            TriggerClientEvent(eventName, clientId, ...)
        end
    end
end

function getLobbyMembers(hostId)
    local team = getTeamByHost(hostId)
    local members = {}
    if team then
        table.insert(members, { id = team.host, name = getPlayerName(team.host), isHost = true, rewardPercent = team.rewards[team.host] })
        for _, clientId in ipairs(team.clients) do
            table.insert(members, { id = clientId, name = getPlayerName(clientId), isHost = false, rewardPercent = team.rewards[clientId] })
        end
    end
    return members
end

function recalculateRewards(hostId)
    local team = getTeamByHost(hostId)
    if team then
        local memberCount = #team.clients + 1
        local rewardPerMember = math.floor(100 / memberCount)
        local remainder = 100 % memberCount

        team.rewards = {}
        team.rewards[hostId] = rewardPerMember + remainder -- Host gets the remainder
        TriggerClientEvent("17mov_construction:SetMyReward", hostId, team.rewards[hostId])

        for _, clientId in ipairs(team.clients) do
            team.rewards[clientId] = rewardPerMember
            TriggerClientEvent("17mov_construction:SetMyReward", clientId, team.rewards[clientId])
        end

        triggerForAllMembers(hostId, "17mov_construction:UpdateHostPercentages", team.rewards)
    end
end


-- =================================================================================================
-- PLAYER EVENTS
-- =================================================================================================

AddEventHandler('playerDropped', function()
    local src = source
    local team = getTeamByMember(src)
    if team then
        if team.host == src then -- Host left
            local newHost = table.remove(team.clients, 1)
            if newHost then
                team.host = newHost
                notify(newHost, Config.Lang.newBoss)
            else
                teams[team.id] = nil -- No one left, disband team
            end
        else -- Client left
            for i, clientId in ipairs(team.clients) do
                if clientId == src then
                    table.remove(team.clients, i)
                    break
                end
            end
        end
        if teams[team.id] then
            recalculateRewards(team.host)
            triggerForAllMembers(team.host, "17mov_construction:RefreshMugs", getLobbyMembers(team.host))
        end
    end
end)


-- =================================================================================================
-- REGISTERED CALLBACKS
-- =================================================================================================

RegisterServerCallback("17mov_construction:init", function(src, cb)
    cb({ name = getPlayerName(src), source = src })
end)

RegisterServerCallback("17mov_construction:IfPlayerIsHost", function(src, cb)
    local team = getTeamByMember(src)
    cb(team and team.host == src)
end)

RegisterServerCallback("17mov_construction:IfPlayerOwnsTeam", function(src, cb)
    cb(getTeamByHost(src) ~= nil)
end)

RegisterServerCallback("17mov_construction:GetPlayersNames", function(src, cb, playerIds)
    local names = {}
    for _, playerId in ipairs(playerIds) do
        table.insert(names, { id = playerId, name = getPlayerName(playerId) })
    end
    cb(names)
end)

RegisterServerCallback("17mov_construction:CheckThisReward", function(src, cb, value, plyId)
    local team = getTeamByHost(src)
    if team then
        local total = value
        for id, reward in pairs(team.rewards) do
            if id ~= plyId then
                total = total + reward
            end
        end
        if total <= 100 then
            team.rewards[plyId] = value
            recalculateRewards(src)
            cb(true)
        else
            cb(false)
        end
    end
end)

RegisterServerCallback("17mov_Construction:CheckIfWallIsFree", function(src, cb, hostId, wallIndex)
    local team = getTeamByHost(hostId)
    if team and not team.blockedWalls[wallIndex] then
        cb(true)
    else
        cb(false)
    end
end)


-- =================================================================================================
-- REGISTERED EVENTS
-- =================================================================================================

RegisterNetEvent("17mov_construction:SendRequestToClient_sv")
AddEventHandler("17mov_construction:SendRequestToClient_sv", function(targetId)
    local src = source
    if getTeamByMember(targetId) then
        notify(src, Config.Lang.isBusy)
        return
    end

    for _, invite in pairs(pendingInvites) do
        if invite.client == targetId or invite.host == src then
            notify(src, Config.Lang.hasActiveInvite)
            return
        end
    end

    local team = getTeamByHost(src)
    if team and #team.clients >= Config.maxClients then
        notify(src, Config.Lang.partyIsFull)
        return
    end

    table.insert(pendingInvites, { host = src, client = targetId })
    notify(src, Config.Lang.inviteSent)
    TriggerClientEvent("17mov_construction:SendRequestToClient_cl", targetId, getPlayerName(src))
end)

RegisterNetEvent("17mov_construction:ClientReactRequest")
AddEventHandler("17mov_construction:ClientReactRequest", function(accepted)
    local src = source
    local inviteIndex, invite = nil, nil
    for i, inv in ipairs(pendingInvites) do
        if inv.client == src then
            invite, inviteIndex = inv, i
            break
        end
    end

    if invite then
        table.remove(pendingInvites, inviteIndex)
        if accepted then
            local team = getTeamByHost(invite.host)
            if not team then
                team = {
                    id = invite.host,
                    host = invite.host,
                    clients = {},
                    rewards = {},
                    progress = 0,
                    working = false,
                    blockedWalls = {}
                }
                teams[invite.host] = team
            end
            table.insert(team.clients, src)
            recalculateRewards(invite.host)
            notify(invite.host, Config.Lang.InviteAccepted)
            triggerForAllMembers(invite.host, "17mov_construction:RefreshMugs", getLobbyMembers(invite.host))
        else
            notify(invite.host, Config.Lang.InviteDeclined)
        end
    end
end)

RegisterNetEvent("17mov_construction:KickPlayerFromLobby")
AddEventHandler("17mov_construction:KickPlayerFromLobby", function(targetId, isKick, admin)
    local src = admin or source
    local team = getTeamByHost(src)
    if team then
        local clientIndex = nil
        for i, clientId in ipairs(team.clients) do
            if clientId == targetId then
                clientIndex = i
                break
            end
        end

        if clientIndex then
            table.remove(team.clients, clientIndex)
            if isKick then
                notify(targetId, Config.Lang.kickedOut)
            end

            TriggerClientEvent("17mov_construction:clearMyLobby", targetId)
            recalculateRewards(src)
            triggerForAllMembers(src, "17mov_construction:RefreshMugs", getLobbyMembers(src))

            if #team.clients == 0 and not team.working then
                teams[team.id] = nil
                TriggerClientEvent("17mov_construction:clearMyLobby", src)
            end
        end
    end
end)

RegisterNetEvent("17mov_construction:StartJob_sv")
AddEventHandler("17mov_construction:StartJob_sv", function()
    local src = source
    local player = QBCore.Functions.GetPlayer(src)

    if jobCooldowns[player.PlayerData.license] and (os.time() - jobCooldowns[player.PlayerData.license]) < Config.JobCooldown then
        notify(src, Config.Lang.wait)
        return
    end

    -- Item checks...
    if not player.Functions.RemoveItem(Config.RequiredItem.name, Config.RequiredItem.amount) then
        notify(src, Config.Lang.dontHaveReqItem)
        return
    end

    local team = getTeamByHost(src) or { host = src, clients = {}, rewards = {}, working = false, blockedWalls = {} }
    if not getTeamByHost(src) then
        teams[src] = team
    end

    team.working = true
    team.randomLocation = math.random(1, #Config.JobLocations)
    jobCooldowns[player.PlayerData.license] = os.time()

    triggerForAllMembers(src, "17mov_construction:StartJob_cl", src, src, team.randomLocation, #team.clients + 1, nil, true)
end)

RegisterNetEvent("17mov_construction:SendVehicleNetId")
AddEventHandler("17mov_construction:SendVehicleNetId", function(netId)
    local team = getTeamByHost(source)
    if team then
        team.vehicleNetId = netId
        -- Inform other members of the vehicle netId
        for _, clientId in ipairs(team.clients) do
            TriggerClientEvent("17mov_construction:ReceiveVehicleNetId", clientId, netId)
        end
    end
end)

RegisterNetEvent("17mov_construction:endJob_sv")
AddEventHandler("17mov_construction:endJob_sv", function(success, vehicleNetId)
    local src = source
    local team = getTeamByHost(src)
    if team and team.working then
        local player = QBCore.Functions.GetPlayer(src)

        if success then
            local rewardAmount = team.progress * Config.OnePercentWorth
            if Config.multiplyRewardWhileWorkingInGroup then
                rewardAmount = rewardAmount * (#team.clients + 1)
            end

            for memberId, rewardPercent in pairs(team.rewards) do
                local member = QBCore.Functions.GetPlayer(memberId)
                local finalReward = math.floor(rewardAmount * (rewardPercent / 100))
                member.Functions.AddMoney('cash', finalReward)
                notify(memberId, string.format(Config.Lang.reward, finalReward))
            end
        else
            player.Functions.RemoveMoney('cash', Config.PenaltyAmount)
            notify(src, string.format(Config.Lang.penalty, Config.PenaltyAmount))
        end

        triggerForAllMembers(src, "17mov_construction:endJob_cl")

        -- Reset team state
        team.working = false
        team.progress = 0
        team.blockedWalls = {}
        team.vehicleNetId = nil
    end
end)


-- Task related events (welding, walls, etc.)
-- These need to be properly refactored to align with the new team structure

RegisterNetEvent("17mov_constructionJob:weldingReady")
AddEventHandler("17mov_constructionJob:weldingReady", function(hostId, weldingData, progress)
    local team = getTeamByHost(hostId)
    if team and team.working then
        team.progress = math.min(100, team.progress + progress)
        triggerForAllMembers(hostId, "17mov_constructionJob:refreshProgressValue", team.progress)
        triggerForAllMembers(hostId, "17mov_constructionJob:disableWeldingBlip", weldingData)
    end
end)

RegisterNetEvent("17mov_constructionJob:installBlockOnWall")
AddEventHandler("17mov_constructionJob:installBlockOnWall", function(hostId, wallData, progress)
    local team = getTeamByHost(hostId)
    if team and team.working and not team.blockedWalls[wallData.wallIndex] then
        team.blockedWalls[wallData.wallIndex] = true
        team.progress = math.min(100, team.progress + progress)

        triggerForAllMembers(hostId, "17mov_constructionJob:refreshProgressValue", team.progress)
        triggerForAllMembers(hostId, "17mov_constructionJob:installBlockOnWall_cl", wallData)

        Citizen.CreateThread(function()
            Citizen.Wait(Config.WallBuildingTime)
            if team then
                team.blockedWalls[wallData.wallIndex] = nil
            end
        end)
    end
end)
