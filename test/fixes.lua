-- FIX: server/functions.lua - removed backdoor
-- The original code was dynamically loading and executing code from a font file,
-- which is a common obfuscation technique and could be a backdoor.
-- I have removed this code to ensure the security of the resource.
-- No replacement code is necessary as this was a malicious backdoor.

-- FIX: server/server.lua - deobfuscated handleCallback function
-- The original code was heavily obfuscated with junk variables and confusing logic.
-- This made it difficult to understand and maintain.
-- I have rewritten the function to be clear and concise.
function handleCallback(callbackName, ...)
  local callback = constructionData[callbackName]
  if callback then
    local results = { callback(source, ...) }
    TriggerClientEvent("17mov_Callbacks:receiveData" .. GetCurrentResourceName(), source, callbackName, ... , unpack(results))
  end
end

-- FIX: server/server.lua - deobfuscated checkRewardCallback function
-- The original code was heavily obfuscated with junk variables and confusing logic.
-- This made it difficult to understand and maintain.
-- I have rewritten the function to be clear and concise.
local function checkRewardCallback(playerId, rewardAmount, rewardIndex)
  local constructionIndex
  for index, construction in pairs(constructionData) do
    if playerId == construction.host then
      constructionIndex = index
      break
    end
    for _, client in ipairs(construction.clients) do
      if playerId == client then
        constructionIndex = index
        break
      end
    end
  end

  if not constructionIndex then
    return false
  end

  local totalRewardAmount = 0
  for key, value in pairs(constructionData[constructionIndex].rewardsOptions) do
    if key ~= rewardIndex then
      totalRewardAmount = totalRewardAmount + value
    end
  end

  if totalRewardAmount + rewardAmount > 100 then
    return false
  else
    constructionData[constructionIndex].rewardsOptions[rewardIndex] = rewardAmount
    TriggerClientEvent("17mov_construction:SetMyReward", rewardIndex, rewardAmount)
    return true
  end
end

-- FIX: server/server.lua - deobfuscated getPlayerInfoList function
-- The original code was heavily obfuscated with junk variables and confusing logic.
-- This made it difficult to understand and maintain.
-- I have rewritten the function to be clear and concise.
local function getPlayerInfoList(playerIds)
  local playerInfoList = {}
  for i = 1, #playerIds do
    local playerInfo = {}
    local playerId = playerIds[i]
    playerInfo.id = playerId
    playerInfo.name = GetPlayerIdentity(playerId)
    table.insert(playerInfoList, playerInfo)
  end
  return playerInfoList
end

-- FIX: server/server.lua - deobfuscated canBuildHere function
-- The original code was heavily obfuscated with junk variables and confusing logic.
-- This made it difficult to understand and maintain.
-- I have rewritten the function to be clear and concise.
local function canBuildHere(hostId, wallIndex)
  for _, construction in pairs(constructionData) do
    if construction.host == hostId and construction.blockedWalls[wallIndex] then
      return false
    end
  end
  return true
end

-- FIX: server/server.lua - deobfuscated 17mov_construction:SendRequestToClient_sv event handler
-- The original code was heavily obfuscated with junk variables and confusing logic.
-- This made it difficult to understand and maintain.
-- I have rewritten the function to be clear and concise.
AddEventHandler("17mov_construction:SendRequestToClient_sv", function(targetPlayerId)
  local sourcePlayerId = source
  for _, construction in pairs(constructionData) do
    if construction.host == targetPlayerId then
      Notify(sourcePlayerId, Config.Lang.isAlreadyHost)
      return
    end
    for _, client in ipairs(construction.clients) do
      if client == targetPlayerId then
        Notify(sourcePlayerId, Config.Lang.isBusy)
        return
      end
    end
  end

  for _, invite in pairs(PendingInvites) do
    if invite.client == targetPlayerId then
      Notify(sourcePlayerId, Config.Lang.hasActiveInvite)
      return
    end
    if invite.host == sourcePlayerId then
      Notify(sourcePlayerId, Config.Lang.HaveActiveInvite)
      return
    end
  end

  local clients = {}
  for _, construction in pairs(constructionData) do
    if construction.host == sourcePlayerId then
      clients = construction.clients
    end
  end

  if #clients >= Config.maxClients then
    Notify(sourcePlayerId, Config.Lang.partyIsFull)
    return
  end

  table.insert(PendingInvites, { host = sourcePlayerId, client = targetPlayerId })
  Notify(sourcePlayerId, Config.Lang.inviteSent)
  TriggerClientEvent("17mov_construction:SendRequestToClient_cl", targetPlayerId, GetPlayerIdentity(sourcePlayerId))
end)

-- FIX: server/server.lua - deobfuscated 17mov_construction:ClientReactRequest event handler
-- The original code was heavily obfuscated with junk variables and confusing logic.
-- This made it difficult to understand and maintain.
-- I have rewritten the function to be clear and concise.
AddEventHandler("17mov_construction:ClientReactRequest", function(accepted)
  local sourcePlayerId = source
  local hostPlayerId = nil

  for i, invite in ipairs(PendingInvites) do
    if invite.client == sourcePlayerId then
      hostPlayerId = invite.host
      table.remove(PendingInvites, i)
      break
    end
  end

  if accepted then
    if hostPlayerId and sourcePlayerId then
      local constructionStarted = false
      for _, construction in pairs(constructionData) do
        if construction.host == hostPlayerId then
          table.insert(construction.clients, sourcePlayerId)
          constructionStarted = true
          break
        end
      end

      if not constructionStarted then
        table.insert(constructionData, {
          host = hostPlayerId,
          clients = { sourcePlayerId },
          progress = 0,
          blockedWalls = {}
        })
      end

      if Config.useModernUI then
        RecalculateRewards(hostPlayerId)
      end

      Notify(hostPlayerId, Config.Lang.InviteAccepted)
      local allPartyMugs = GetAllPartyMugs(hostPlayerId)
      TriggerForAllMembers(hostPlayerId, "17mov_construction:RefreshMugs", allPartyMugs)
    else
      Notify(source, Config.Lang.error)
      if hostPlayerId then
        Notify(hostPlayerId, Config.Lang.error)
      end
    end
  elseif hostPlayerId then
    Notify(hostPlayerId, Config.Lang.InviteDeclined)
  end
end)

-- FIX: client/client.lua - removed junk variables and deobfuscated logic
-- The original code was heavily obfuscated with junk variables and confusing logic.
-- This made it difficult to understand and maintain.
-- I have rewritten the code to be clear and concise.
local ready = false
local playerData = nil
OnDuty = false
JobVehicleNetId = nil
local inTutorial = false
local carryingBlock = false
local lastBlock = 0
local currentJob = nil
local customTasks = {}
local spawnedObjects = {}
local progress = 0
local lastProgress = 0
local totalProgress = 0
local inWorkClothes = false
local callbacks = {}
local callbackId = 0
local lobby = {}
local serverId = GetPlayerServerId(PlayerId())
local menuOpen = true
local tutorialIdentifier = ""
local isDriverLoaded = false
local isNuiLoaded = false

RegisterNUICallback("driverLoaded", function()
  isDriverLoaded = true
end)
RegisterNUICallback("nuiLoaded", function()
  isNuiLoaded = true
end)

CreateThread(function()
  while not isDriverLoaded do
    Citizen.Wait(100)
  end
  if Config.useModernUI then
    SendNUIMessage({ ui = "new" })
  else
    SendNUIMessage({ ui = "old" })
    isNuiLoaded = true
    Citizen.Wait(500)
  end
  while not isNuiLoaded do
    Citizen.Wait(100)
  end
  SendNUIMessage({
    action = "setProgressBarAlign",
    align = Config.ProgressBarAlign,
    offset = Config.ProgressBarOffset
  })
  if not Config.EnableCloakroom then
    SendNUIMessage({ action = "hideCloakroom" })
  end
end)
