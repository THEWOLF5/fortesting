local constructionSites = {}
local constructionSiteData = {}
local playerConstructionProgress = {}
local maxConstructionStages = 4
local constructionMaterials = {}
local playerLastActivity = {}
local constructionSiteOwners = {}
local playerPings = {}

local getPlayerPing = GetPlayerPing

function GetPlayerPingWrapper(playerId, ...)
  local ping
  if playerId ~= nil then
    ping = getPlayerPing
    local args = {...}
    ping(playerId, unpack(args))
  end
end
GetPlayerPing = GetPlayerPingWrapper

local triggerClientEvent = TriggerClientEvent
function TriggerClientEventWrapper(eventName, playerId, ...)
  if playerId ~= nil then
    triggerClientEvent(eventName, playerId, ...)
  end
end
TriggerClientEvent = TriggerClientEventWrapper

local getPlayerIdentifierByType = GetPlayerIdentifierByType
function GetPlayerIdentifierByTypeWrapper(playerId, identifierType)
  if playerId == nil then
    return 0
  end

  if getPlayerIdentifierByType ~= nil then
    return getPlayerIdentifierByType(playerId, identifierType)
  else
    return GetPlayerIdentifier(playerId, 1)
  end
end
GetPlayerIdentifierByType = GetPlayerIdentifierByTypeWrapper

local useModernUI = Config.useModernUI
if useModernUI then
  function RecalculateRewards(hostPlayerId)
    local constructionSiteIndex = 0
    for index, site in pairs(constructionSites) do
      if site.host == hostPlayerId then
        constructionSiteIndex = index
      end
    end

    local constructionSite = constructionSites[constructionSiteIndex]
    local rewardsOptions = {}
    constructionSite.rewardsOptions = rewardsOptions

    constructionSite = constructionSites[constructionSiteIndex]
    local clientCount = #constructionSite.clients
    clientCount = clientCount + 1

    for i = 1, clientCount - 1, 1 do
      local clientPlayerId = constructionSites[constructionSiteIndex].clients[i]
      local rewards = constructionSites[constructionSiteIndex].rewardsOptions
      local percentage = math.floor(100 / clientCount)
      rewards[clientPlayerId] = percentage
    end

    local rewards = constructionSites[constructionSiteIndex].rewardsOptions
    local hostPercentage = math.floor(100 / clientCount)
    rewards[hostPlayerId] = hostPercentage

    TriggerForAllMembers(hostPlayerId, "17mov_construction:SetMyReward", hostPercentage)

    TriggerClientEvent("17mov_construction:UpdateHostPercentages", hostPlayerId, hostPercentage)
  end
end

function RegisterServerCallback(callbackName, callbackFunction)
  Callbacks[callbackName] = callbackFunction
end

local registerNetEvent = RegisterNetEvent
local getResponseEventName = "17mov_Callbacks:GetResponse" .. GetCurrentResourceName()
local constructionData = {}

function handleCallback(callbackName, argument1, ...)
  local callbackFunction, sourcePlayerId, argument2, argument3, argument4, argument5, argument6, argument7, argument8, argument9, argument10, argument11, argument12, argument13, argument14, argument15, argument16, argument17, argument18, argument19, argument20, argument21, argument22, argument23, argument24, argument25, argument26
  callbackFunction = constructionData
  callbackFunction = callbackFunction[callbackName]
  if nil == callbackFunction then
    return
  end
  sourcePlayerId = source
  callbackFunction = constructionData
  callbackFunction = callbackFunction[callbackName]
  local playerId = sourcePlayerId
  argument2, argument3, argument4, argument5, argument6, argument7, argument8, argument9, argument10, argument11, argument12, argument13, argument14, argument15, argument16, argument17, argument18, argument19, argument20, argument21, argument22, argument23, argument24, argument25, argument26 = ...
  local results = callbackFunction(playerId, argument2, argument3, argument4, argument5, argument6, argument7, argument8, argument9, argument10, argument11, argument12, argument13, argument14, argument15, argument16, argument17, argument18, argument19, argument20, argument21, argument22, argument23, argument24, argument25, argument26)
  local triggerClientEvent = TriggerClientEvent
  local eventName = "17mov_Callbacks:receiveData"
  local resourceName = GetCurrentResourceName()
  eventName = eventName .. resourceName
  local sourcePlayer = sourcePlayerId
  local callback = callbackName
  local arg1 = argument1
  local callbackResults = results
  local result2 = argument2
  local result3 = argument3
  local result4 = argument4
  local result5 = argument5
  local result6 = argument6
  local result7 = argument7
  local result8 = argument8
  local result9 = argument9
  local result10 = argument10
  local result11 = argument11
  local result12 = argument12
  local result13 = argument13
  triggerClientEvent(eventName, sourcePlayer, callback, arg1, callbackResults, result2, result3, result4, result5, result6, result7, result8, result9, result10, result11, result12, result13)
end

RegisterNetEvent(handleCallback)

local citizen = Citizen
local createThread = citizen.CreateThread

function registerConstructionCallbacks()
  local registerServerCallback = RegisterServerCallback
  local checkRewardEventName = "17mov_construction:CheckThisReward"

  local function checkRewardCallback(playerId, rewardAmount, rewardIndex)
    local constructionIndex = 0
    local pairsIterator = pairs
    local constructionDataIterator = constructionData
    pairsIterator, constructionDataIterator, nextConstruction, constructionIndexValue = pairsIterator(constructionDataIterator)

    for constructionIndex, construction in pairsIterator, constructionDataIterator, nextConstruction, constructionIndexValue do
      local hostId = construction.host
      if playerId == hostId then
        constructionIndex = constructionIndex
        break
      end

      local clientIndexStart = 1
      local numberOfClients = #construction.clients
      local clientIndexIncrement = 1

      for clientIndex = clientIndexStart, numberOfClients, clientIndexIncrement do
        local currentClient = construction.clients
        currentClient = currentClient[clientIndex]

        if playerId == currentClient then
          constructionIndex = constructionIndex
          break
        end
      end
    end

    local totalRewardAmount = 0
    local pairsIterator = pairs
    local rewardsOptions = constructionData
    rewardsOptions = rewardsOptions[constructionIndex]
    rewardsOptions = rewardsOptions.rewardsOptions
    pairsIterator, rewardsOptions, nextReward, rewardIndexValue = pairsIterator(rewardsOptions)

    for rewardIndexKey, rewardValue in pairsIterator, rewardsOptions, nextReward, rewardIndexValue do
      if rewardIndexKey ~= rewardIndex then
        totalRewardAmount = totalRewardAmount + rewardValue
      end
    end

    local finalRewardAmount = totalRewardAmount + rewardAmount

    if finalRewardAmount > 100 then
      finalRewardAmount = false
      return finalRewardAmount
    else
      local constructionRewards = constructionData
      constructionRewards = constructionRewards[constructionIndex]
      constructionRewards = constructionRewards.rewardsOptions
      constructionRewards[rewardIndex] = rewardAmount
      local triggerClientEvent = TriggerClientEvent
      local setRewardEventName = "17mov_construction:SetMyReward"
      local rewardId = rewardIndex
      local rewardPoints = rewardAmount
      triggerClientEvent(setRewardEventName, rewardId, rewardPoints)
      finalRewardAmount = true
      return finalRewardAmount
    end
  end

  registerServerCallback(checkRewardEventName, checkRewardCallback)

  local registerServerCallback = RegisterServerCallback
  local getPlayersNamesEventName = "17mov_construction:GetPlayersNames"

  local function getPlayersNamesCallback(playerId, playerList)
    local playerNames = {}
    local indexStart = 1
    local numberOfPlayers = #playerList
    local indexIncrement = 1
-- Fonction interne pour récupérer les informations des joueurs
  local function getPlayerInfoList(playerIds)
    local playerInfoList = {}

    for i = 1, #playerIds do
      local playerInfo = {}
      local playerId = playerIds[i]
      playerInfo.id = playerId

      local playerIdentity = GetPlayerIdentity(playerId)
      playerInfo.name = playerIdentity

      table.insert(playerInfoList, playerInfo)
    end

    return playerInfoList
  end

  -- Enregistrement du callback serveur pour récupérer les membres du lobby
  local registerServerCallback = RegisterServerCallback
  local getLobbyMembersEventName = "17mov_construction:GetLobbyMembers"
  function getLobbyMembers(source, teamHostId)
    if teamHostId == nil then
      return {}
    end

    local lobbyMembers = {}
    lobbyMembers[1] = teamHostId

    for teamId, teamData in pairs(teams) do
      if teamData.host == teamHostId then
        for i = 1, #teamData.clients do
          local client = teamData.clients[i]
          table.insert(lobbyMembers, client)
        end
      end
    end

    return lobbyMembers
  end
  registerServerCallback(getLobbyMembersEventName, getLobbyMembers)

  -- Enregistrement du callback serveur pour vérifier si un joueur possède une équipe
  local ifPlayerOwnsTeamEventName = "17mov_construction:IfPlayerOwnsTeam"
  function ifPlayerOwnsTeam(source)
    local playerOwnsTeam = false

    for _, teamData in pairs(teams) do
      if teamData.host == source then
        playerOwnsTeam = true
        break
      end
    end

    return playerOwnsTeam
  end
  registerServerCallback(ifPlayerOwnsTeamEventName, ifPlayerOwnsTeam)

  -- Enregistrement du callback serveur pour vérifier si un joueur est l'hôte
  local ifPlayerIsHostEventName = "17mov_construction:IfPlayerIsHost"
  function ifPlayerIsHost(source)
    local isHost = true
    local teamIdToRemove = 0

    for teamId, teamData in pairs(teams) do
      for i = 1, #teamData.clients do
        local client = teamData.clients[i]
        if client == source then
          isHost = false
          teamIdToRemove = teamId
          break
        end
      end
    end

    if not isHost then
      local playerPing = GetPlayerPing(teams[teamIdToRemove].host)
      if playerPing == 0 then
        isHost = true
        teams[teamIdToRemove].host = source
      end
    end

    return isHost
  end
  registerServerCallback(ifPlayerIsHostEventName, ifPlayerIsHost)

  -- Enregistrement du callback serveur pour initialiser les informations du joueur
  local initEventName = "17mov_construction:init"
  function initializePlayerInfo(source)
    local playerInfo = {}
    local playerIdentity = GetPlayerIdentity(source)
    playerInfo.name = playerIdentity
    playerInfo.source = source
    return playerInfo
  end
  registerServerCallback(initEventName, initializePlayerInfo)

  -- Enregistrement du callback serveur pour vérifier si un mur est libre
  local checkIfWallIsFreeEventName = "17mov_Construction:CheckIfWallIsFree"
  function checkIfWallIsFree(source, arg1, arg2)
local function canBuildHere(hostId, wallIndex)
  local canBuild = true
  local pairsIterator = pairs
  local constructionData = ConstructionData

  for constructionId, construction in pairsIterator(constructionData) do
    local host = construction.host
    if host == hostId then
      local blockedWalls = construction.blockedWalls
      local isWallBlocked = blockedWalls[wallIndex]
      if isWallBlocked then
        canBuild = false
      end
    end
  end
  return canBuild
end

RegisterNetEvent("17mov_construction:SendRequestToClient_sv")

AddEventHandler("17mov_construction:SendRequestToClient_sv", function(targetPlayerId)
  local sourcePlayerId = source
  local pairsIterator = pairs
  local constructionData = ConstructionData

  for constructionId, construction in pairsIterator(constructionData) do
    local hostPlayerId = construction.host
    if hostPlayerId == targetPlayerId then
      local notify = Notify
      local playerId = sourcePlayerId
      local isAlreadyHostMessage = Config.Lang.isAlreadyHost
      notify(playerId, isAlreadyHostMessage)
      return
    else
      local startingIndex = 1
      local clients = construction.clients
      local numberOfClients = #clients
      local increment = 1
      for i = startingIndex, numberOfClients, increment do
        local clientPlayerId = construction.clients[i]
        if clientPlayerId == targetPlayerId then
          local notify = Notify
          local playerId = sourcePlayerId
          local isBusyMessage = Config.Lang.isBusy
          notify(playerId, isBusyMessage)
          return
        end
      end
    end
  end

  local pairsIterator = pairs
  local pendingInvites = PendingInvites

  for inviteId, invite in pairsIterator(pendingInvites) do
    local clientPlayerId = invite.client
    if clientPlayerId == targetPlayerId then
      local notify = Notify
      local playerId = sourcePlayerId
      local hasActiveInviteMessage = Config.Lang.hasActiveInvite
      notify(playerId, hasActiveInviteMessage)
      return
    end

    local hostPlayerId = invite.host
    if hostPlayerId == sourcePlayerId then
      local clientPlayerId = invite.client
      if nil ~= clientPlayerId then
        local notify = Notify
        local playerId = sourcePlayerId
        local haveActiveInviteMessage = Config.Lang.HaveActiveInvite
        notify(playerId, haveActiveInviteMessage)
        return
      end
    end
  end

  local clients = {}
  local pairsIterator = pairs
  local constructionData = ConstructionData

  for constructionId, construction in pairsIterator(constructionData) do
    local hostPlayerId = construction.host
    if hostPlayerId == sourcePlayerId then
      clients = construction.clients
    end
  end

  local numberOfClients = #clients
  local maxClients = Config.maxClients

  if numberOfClients >= maxClients then
    local notify = Notify
    local playerId = sourcePlayerId
    local partyIsFullMessage = Config.Lang.partyIsFull
    notify(playerId, partyIsFullMessage)
    return
  end

  local tableInsert = table.insert
  local pendingInvites = PendingInvites
  local newInvite = {}
  newInvite.host = sourcePlayerId
  newInvite.client = targetPlayerId
  tableInsert(pendingInvites, newInvite)

  local notify = Notify
  local playerId = sourcePlayerId
  local inviteSentMessage = Config.Lang.inviteSent
  notify(playerId, inviteSentMessage)

  local triggerClientEvent = TriggerClientEvent
  local eventName = "17mov_construction:SendRequestToClient_cl"
  local target = targetPlayerId
  local getPlayerIdentity = GetPlayerIdentity
  local host = sourcePlayerId
  local identity = getPlayerIdentity(host)
  triggerClientEvent(eventName, target, identity)
end)
local constructionData = {} -- Stocke les données de construction (host, clients, progress, blockedWalls)

RegisterNetEvent("17mov_construction:ClientReactRequest")

AddEventHandler("17mov_construction:ClientReactRequest", function(accepted)
  local sourcePlayerId = source
  local hostPlayerId = nil
  local constructionStarted = false

  for constructionId, construction in pairs(constructionData) do
    local clientPlayerId = construction.client
    if clientPlayerId == sourcePlayerId then
      hostPlayerId = construction.host
      constructionData[constructionId] = nil
      break
    end
  end

  if accepted then
    if hostPlayerId ~= nil and sourcePlayerId ~= nil then
      for constructionId, construction in pairs(constructionData) do
        if construction.host == hostPlayerId then
          local clients = construction.clients
          if clients ~= nil then
            table.insert(clients, sourcePlayerId)
            constructionStarted = true
          end
        end
      end

      if not constructionStarted then
        local newConstruction = {}
        newConstruction.host = hostPlayerId
        newConstruction.clients = {sourcePlayerId}
        newConstruction.progress = 0
        newConstruction.blockedWalls = {}
        table.insert(constructionData, newConstruction)
      end

      if Config.useModernUI then
        RecalculateRewards(hostPlayerId)
      end

      Notify(hostPlayerId, Config.Lang.InviteAccepted)
      local allPartyMugs = GetAllPartyMugs(hostPlayerId)
      TriggerForAllMembers(hostPlayerId, "17mov_construction:RefreshMugs", allPartyMugs)
    else
      Notify(source, Config.Lang.error)
      Notify(hostPlayerId, Config.Lang.error)
    end
  else
    Notify(hostPlayerId, Config.Lang.InviteDeclined)
  end
end)

RegisterNetEvent("17mov_construction:KickPlayerFromLobby")

AddEventHandler("17mov_construction:KickPlayerFromLobby", function(targetPlayerId, constructionId, isAdmin)
  local playerIdToKick = targetPlayerId
  local sourcePlayerId = nil

  if isAdmin == nil then
    sourcePlayerId = source
    local construction = constructionData[constructionId]
    if construction then
      local clients = construction.clients
      if clients then
        for i, clientId in ipairs(clients) do
          if clientId == playerIdToKick then
            table.remove(clients, i)
            break
          end
        end
      end
    end
  else
    -- Gérer le cas où isAdmin est défini (peut-être pour une suppression forcée)
    -- La logique ici dépend de la façon dont l'admin doit interagir
  end

  TriggerClientEvent("17mov_construction:KickedFromLobby", playerIdToKick)
end)
local kicked = A1_2
  local partyId = L4_2
  local playerId = L3_2
  local partyList = L0_1
  local playerToRemoveId = A2_2

  if playerToRemoveId then
    local pairsIterator = pairs
    local partyListCopy = partyList
    pairsIterator, partyListCopy, _, _ = pairsIterator(partyListCopy)

    for partyIndex, partyData in pairsIterator, partyListCopy, _, _ do
      local clientIndexStart = 1
      local numberOfClients = #partyData.clients
      local clientIndexIncrement = 1

      for clientIndex = clientIndexStart, numberOfClients, clientIndexIncrement do
        local client = partyData.host

        if client == partyId then
          client = partyData.clients
          client = client[clientIndex]

          if client == playerId then
            client = partyData.clients
            client[clientIndex] = nil
            break
          end
        end
      end
    end
  else
    local pairsIterator = pairs
    local partyListCopy = partyList
    pairsIterator, partyListCopy, _, _ = pairsIterator(partyListCopy)

    for partyIndex, partyData in pairsIterator, partyListCopy, _, _ do
      local clientIndexStart = 1
      local numberOfClients = #partyData.clients
      local clientIndexIncrement = 1

      for clientIndex = clientIndexStart, numberOfClients, clientIndexIncrement do
        local client = partyData.clients
        client = client[clientIndex]

        if client == playerToRemoveId then
          local hostId = partyData.host
          client = partyData.clients
          client[clientIndex] = nil
          break
        end
      end
    end
  end

  if kicked then
    local notify = Notify
    local playerIdToKick = playerId
    local config = Config
    local kickedOutMessage = config.Lang.kickedOut
    notify(playerIdToKick, kickedOutMessage)
  end

  local useModernUI = Config.useModernUI

  if useModernUI then
    local mugshotList = {}
    local mugshotData = {}
    mugshotData.id = playerId
    local getPlayerIdentity = GetPlayerIdentity
    local playerIdentity = getPlayerIdentity(playerId)
    mugshotData.name = playerIdentity
    mugshotData.isHost = true
    mugshotList[1] = mugshotData

    local triggerClientEvent = TriggerClientEvent
    local refreshMugsEventName = "17mov_construction:RefreshMugs"
    local targetPlayerId = playerId
    local mugshots = mugshotList
    local playerIdForEvent = playerId
    triggerClientEvent(refreshMugsEventName, targetPlayerId, mugshots, playerIdForEvent)

    local triggerClientEvent = TriggerClientEvent
    local clearMyLobbyEventName = "17mov_construction:clearMyLobby"
    local playerIdToClear = playerId
    triggerClientEvent(clearMyLobbyEventName, playerIdToClear)

    local triggerClientEvent = TriggerClientEvent
    local setMyRewardEventName = "17mov_construction:SetMyReward"
    local playerIdToReward = playerId
    local rewardAmount = 100
    triggerClientEvent(setMyRewardEventName, playerIdToReward, rewardAmount)

    local getAllPartyMugs = GetAllPartyMugs
    local partyIdForMugs = partyId
    local partyMugs = getAllPartyMugs(partyIdForMugs)

    local triggerForAllMembers = TriggerForAllMembers
    local partyIdToUpdate = partyId
    local refreshMugsEvent = "17mov_construction:RefreshMugs"
    local mugshotsToUpdate = partyMugs
    triggerForAllMembers(partyIdToUpdate, refreshMugsEvent, mugshotsToUpdate)

    local recalculateRewards = RecalculateRewards
    local partyIdForRecalc = partyId
    recalculateRewards(partyIdForRecalc)

    local pairsIterator = pairs
    local partyListCopy = partyList
    pairsIterator, partyListCopy, _, _ = pairsIterator(partyListCopy)

    for partyIndex, partyData in pairsIterator, partyListCopy, _, _ do
      local numberOfClients = #partyData.clients

      if 0 == numberOfClients then
        local hostId = partyData.host

        if hostId == partyId then
          local partyListToUpdate = partyList
          partyListToUpdate[partyIndex] = nil

          local triggerClientEvent = TriggerClientEvent
          local clearMyLobbyEvent = "17mov_construction:clearMyLobby"
          local partyHostId = partyId
          triggerClientEvent(clearMyLobbyEvent, partyHostId)
        end
      end
    end
  else
    local mugshotList = {}
    local mugshotData = {}
    mugshotData.id = playerId
    local getPlayerIdentity = GetPlayerIdentity
    local playerIdentity = getPlayerIdentity(playerId)
    mugshotData.name = playerIdentity
    mugshotData.isHost = true
    mugshotList[1] = mugshotData

    local triggerClientEvent = TriggerClientEvent
    local refreshMugsEventName = "17mov_construction:RefreshMugs"
    local targetPlayerId = playerId
    local mugshots = mugshotList
    local playerIdForEvent = playerId
    triggerClientEvent(refreshMugsEventName, targetPlayerId, mugshots, playerIdForEvent)

    local getAllPartyMugs = GetAllPartyMugs
    local partyIdForMugs = partyId
    local partyMugs = getAllPartyMugs(partyIdForMugs)

    local triggerForAllMembers = TriggerForAllMembers
    local partyIdToUpdate = partyId
    local refreshMugsEvent = "17mov_construction:RefreshMugs"
    local mugshotsToUpdate = partyMugs
    triggerForAllMembers(partyIdToUpdate, refreshMugsEvent, mugshotsToUpdate)

    local pairsIterator = pairs
    local partyListCopy = partyList
    pairsIterator, partyListCopy, _, _ = pairsIterator(partyListCopy)
  end
local jobLocations = {}
local playerLastTaskCompletionTime = {}

local function cleanupEmptyJobLocations()
  for locationName, locationData in pairs(jobLocations) do
    local clients = locationData.clients
    local clientCount = #clients
    if clientCount == 0 then
      local hostId = locationData.host
      for playerId, playerData in pairs(jobLocations) do
        if playerData.host == hostId then
          jobLocations[locationName] = nil
        end
      end
    end
  end
end

RegisterNetEvent("17movement_builder:disableCustomTask")
local function disableCustomTask(locationName, taskId)
  TriggerForAllMembers(locationName, "17mov_construction:disableThisCustomTask", taskId)
end

RegisterNetEvent("17movement_builder:CustomTaskDone")
local function customTaskDone(locationName, taskData, taskId)
  local playerId = source
  local jobLocationIndex = nil

  for index, locationData in pairs(jobLocations) do
    if locationData.host == locationName then
      jobLocationIndex = index
      break
    end
  end

  if not jobLocationIndex then
    return
  end

  local jobLocationData = jobLocations[jobLocationIndex]
  local randomLocation = jobLocationData.randomLocation

  if taskId then
    local progressValue = taskData.progressValue
    local configTask = Config.JobLocations[randomLocation].customTasks[taskId]
    local configProgressValue = configTask.progressValue

    if progressValue ~= configProgressValue then
      return
    end
  end

  local pedInteractionCoords = vec3(
    Config.JobLocations[randomLocation].customTasks[taskId].pedInteractionCoords.x,
    Config.JobLocations[randomLocation].customTasks[taskId].pedInteractionCoords.y,
    Config.JobLocations[randomLocation].customTasks[taskId].pedInteractionCoords.z
  )

  local playerPed = GetPlayerPed(source)
  local playerCoords = GetEntityCoords(playerPed)
  local distance = #(pedInteractionCoords - playerCoords)

  if distance > 10.0 then
    return
  end

  local playerJobData = jobLocations[jobLocationIndex]
  local completedTasks = jobLocations[jobLocationIndex].completedCustomTasks

  if not completedTasks then
    completedTasks = {}
  end
  playerJobData.completedCustomTasks = completedTasks

  local taskAlreadyCompleted = jobLocations[jobLocationIndex].completedCustomTasks[taskId]
  if taskAlreadyCompleted then
    return
  end

  local completionDelay = 5000
  local currentTime = GetGameTimer()
  local lastCompletionTime = playerLastTaskCompletionTime[playerId]

  if lastCompletionTime then
    local timeSinceLastCompletion = currentTime - lastCompletionTime
    if completionDelay > timeSinceLastCompletion then
      return
    end
  end

  playerLastTaskCompletionTime[playerId] = currentTime

  local playerJobLocationData = jobLocations[jobLocationIndex]
  playerJobLocationData.completedCustomTasks[taskId] = true

  cleanupEmptyJobLocations()
end
-- Event to disable a specific pipe
RegisterNetEvent("17mov_Construction:DisableThisPipe")
function disableThisPipe(constructionHostId, pipeData)
  local triggerClientEvent = TriggerClientEvent
  local eventName = "17mov_construction:disableThisPipe"
  triggerClientEvent(constructionHostId, eventName, pipeData)
end

-- Event to handle pouring concrete
RegisterNetEvent("17mov_construction:PourConcrete")
function pourConcrete(constructionHostId, concreteData, holeData)
  local playerSource = source
  local constructionIndex = nil

  -- Find the construction site index based on the host ID
  for index, constructionSite in pairs(ConstructionSites) do
    if constructionHostId == constructionSite.host then
      constructionIndex = index
      break
    end
  end

  -- If the construction site is not found, exit the function
  if not constructionIndex then
    return
  end

  local constructionSite = ConstructionSites[constructionIndex]
  local randomLocation = constructionSite.randomLocation

  -- Validate progress value if hole data is provided
  if holeData then
    local progressValue = concreteData.progressValue
    local jobLocationConfig = Config.JobLocations[randomLocation]
    local mixerTargetLocations = jobLocationConfig.mixerTargetLocations
    local holeIndex = holeData.holeIndex
    local concreteSettings = mixerTargetLocations[holeIndex].concreteSettings
    local expectedProgressValue = concreteSettings.progressValue

    -- If the progress value doesn't match the expected value, exit the function
    if progressValue ~= expectedProgressValue then
      return
    end
  end

  -- Calculate the distance between the player and the concrete mixer
  local vec3 = vector3
  local jobLocationConfig = Config.JobLocations[randomLocation]
  local mixerTargetLocations = jobLocationConfig.mixerTargetLocations
  local holeIndex = holeData.holeIndex
  local concreteSettings = mixerTargetLocations[holeIndex].concreteSettings
  local startingLocation = concreteSettings.startingLoc
  local mixerLocation = vec3(startingLocation.xyz)

  local getEntityCoords = GetEntityCoords
  local getPlayerPed = GetPlayerPed
  local playerPed = getPlayerPed(playerSource)
  local playerCoords = getEntityCoords(playerPed)
  local distance = mixerLocation - playerCoords
  local distanceMagnitude = #distance

  -- If the player is too far from the mixer, exit the function
  if distanceMagnitude > 10.0 then
    return
  end

  -- Trigger the client-side event to pour concrete
  local triggerClientEvent = TriggerClientEvent
  local eventName = "17mov_construction:PourConcrete_cl"
  triggerClientEvent(constructionHostId, eventName, concreteData, holeData)

  -- Update the construction progress
  for index, constructionSite in pairs(ConstructionSites) do
    if constructionHostId == constructionSite.host then
      local progressValueToAdd = concreteData.progressValue
      constructionSite.progress = constructionSite.progress + progressValueToAdd

      -- Cap the progress at 100
      if constructionSite.progress > 100 then
        constructionSite.progress = 100
      end

      -- Refresh the progress value on the client
      local triggerClientEvent = TriggerClientEvent
      local eventName = "17mov_constructionJob:refreshProgressValue"
      triggerClientEvent(constructionHostId, eventName, constructionSite.progress)
      break
    end
  end

  -- Spawn custom props for the builder
  local triggerClientEvent = TriggerClientEvent
  local eventName = "17mov_Builder:SpawnCustomProps"
  triggerClientEvent(constructionHostId, eventName, concreteData, holeData)
end
local triggerForAllMembers = function(jobName, eventName, progressData, pipeData)
  for k, v in pairs(ESX) do
    if v.host == jobName then
      TriggerClientEvent(eventName, k, progressData, pipeData)
    end
  end
end

RegisterNetEvent("17mov_constructionJob:refreshProgressValue")
local refreshProgressValueEvent = function(jobName, eventName, progress)
  triggerForAllMembers(jobName, eventName, progress)
end

RegisterNetEvent("17mov_Construction:SpawnPipe_SV")
local spawnPipeServerEvent = function(jobName, progressData, pipeData)
  local playerId = source
  local jobData = nil

  -- Recherche des données du job correspondant au nom du job
  for jobId, job in pairs(ESX) do
    if jobName == job.host then
      jobData = jobId
      break
    end
  end

  -- Si le job n'est pas trouvé, on arrête
  if not jobData then
    return
  end

  -- Récupération des données du job
  local job = ESX[jobData]
  local jobBuiltPipes = ESX[jobData].builtPipes

  -- Initialisation de la table des pipes construites si elle n'existe pas
  if not jobBuiltPipes then
    jobBuiltPipes = {}
  end
  job.builtPipes = jobBuiltPipes

  -- Récupération de la position aléatoire
  local randomLocation = ESX[jobData].randomLocation

  -- Création d'une clé unique pour la pipe
  local pipeKey = string.format("%d-%d", pipeData.holeIndex, pipeData.pipeIndex)

  -- Si la pipe est déjà construite, on arrête
  if job.builtPipes[pipeKey] then
    return
  end

  -- Calcul du temps d'installation de la pipe
  local pipeInstallingTime = Config.PipeInstallingTime * 0.8

  -- Récupération du temps actuel
  local currentTime = GetGameTimer()

  -- Récupération du dernier temps d'installation de la pipe pour ce joueur
  local lastPipeInstallTime = lastPipeInstallTimes[playerId]

  -- Si le joueur a installé une pipe récemment, on arrête
  if lastPipeInstallTime then
    local timeSinceLastInstall = currentTime - lastPipeInstallTime
    if pipeInstallingTime > timeSinceLastInstall then
      return
    end
  end

  -- Mise à jour du dernier temps d'installation de la pipe pour ce joueur
  lastPipeInstallTimes[playerId] = currentTime

  -- Vérification de la valeur de progression
  if pipeData then
    local progressValue = progressData.progressValue
    local targetProgressValue = Config.JobLocations[randomLocation].mixerTargetLocations[pipeData.holeIndex].pipes[pipeData.pipeIndex].progressValue
    if progressValue ~= targetProgressValue then
      return
    end
  end

  -- Récupération des coordonnées d'installation de la pipe
  local installCoords = vec3(Config.JobLocations[randomLocation].mixerTargetLocations[pipeData.holeIndex].pipes[pipeData.pipeIndex].pedInstallingCoords.xyz)

  -- Récupération des coordonnées du joueur
  local playerPed = GetPlayerPed(source)
  local playerCoords = GetEntityCoords(playerPed)

  -- Vérification de la distance entre le joueur et les coordonnées d'installation
  local distance = # (installCoords - playerCoords)
  if distance > 10.0 then
    return
  end

  -- Déclenchement de l'événement pour faire apparaître la pipe
  triggerForAllMembers(jobName, "17mov_ConstructionJob:SpawnPipe", progressData, pipeData)

  -- Mise à jour de la progression du job
  for jobId, job in pairs(ESX) do
    if jobName == job.host then
      local currentProgress = job.progress
      local progressIncrement = progressData.progressValue
      currentProgress = currentProgress + progressIncrement
      job.progress = currentProgress

      -- Limitation de la progression à 100%
      if currentProgress > 100 then
        job.progress = 100
      end

      -- Déclenchement de l'événement pour rafraîchir la valeur de progression
      local refreshProgressEventName = "17mov_constructionJob:refreshProgressValue"
      local currentProgressValue = job.progress
      triggerForAllMembers(jobName, refreshProgressEventName, currentProgressValue)
      break
    end
  end
end

RegisterNetEvent("17mov_Construction:SpawnPipe_SV")
AddEventHandler("17mov_Construction:SpawnPipe_SV", spawnPipeServerEvent)
local constructionSites = {}
local lastBlockPlacementTime = {}

local function triggerForAllMembers(source, eventName, ...)
  for k, v in ipairs(GetPlayers()) do
    local playerId = tonumber(v)
    if playerId ~= source then
      TriggerClientEvent(eventName, playerId, ...)
    end
  end
end

RegisterNetEvent("17mov_constructionJob:refreshPipeStatus")
local function refreshPipeStatus(constructionSiteId, pipeId)
  local constructionSite = constructionSites[constructionSiteId]
  constructionSite.builtPipes[pipeId] = true

  for _, constructionSiteData in pairs(constructionSites) do
    if constructionSiteId == constructionSiteData.host then
      triggerForAllMembers(A0_2, "17mov_constructionJob:refreshProgressValue", constructionSiteData.progress) -- A0_2 is not used, so it's probably the source. Refactoring later if needed
      break
    end
  end
end

RegisterNetEvent("17mov_constructionJob:RemoveMixerPickupBlip")
local function removeMixerPickupBlip(source, mixerCoords)
  triggerForAllMembers(source, "17mov_constructionJob:RemoveMixerPickupBlip_cl")

  for _, mixerSpawn in pairs(Config.MixerSpawns) do
    if mixerSpawn.coords == mixerCoords then
      mixerSpawn.avalible = true
    end
  end
end

RegisterNetEvent("17mov_constructionJob:sendMixer")
local function sendMixer(source, mixerNetId)
  for _, constructionSiteData in pairs(constructionSites) do
    if source == constructionSiteData.host then
      constructionSiteData.mixerNetId = mixerNetId
    end
  end

  triggerForAllMembers(source, "17mov_constructionJob:sendMixer_cl", mixerNetId)
end

RegisterNetEvent("17mov_constructionJob:deleteBlockFromSpawn")
local function deleteBlockFromSpawn(source, blockId)
  triggerForAllMembers(source, "17mov_constructionJob:deleteBlockFromSpawn_cl", blockId)
end

RegisterNetEvent("17mov_constructionJob:installBlockOnWall")
local function installBlockOnWall(constructionSiteId, wallId, blockId)
  local playerSource = source
  local buildingCooldown = Config.WallBuildingTime * 0.8
  local currentTime = GetGameTimer()

  if lastBlockPlacementTime[playerSource] then
    local timeSinceLastPlacement = currentTime - lastBlockPlacementTime[playerSource]
    if buildingCooldown > timeSinceLastPlacement then
      print(("Install block event REJECTED - Player %s installing blocks too fast. Current Time: %s Last value: %s Cooldown time: %s"):format(playerSource, currentTime, lastBlockPlacementTime[playerSource], buildingCooldown))
      return
    end
  end

  lastBlockPlacementTime[playerSource] = currentTime

  local constructionSiteIndex = nil
  for index, constructionSiteData in pairs(constructionSites) do
    if constructionSiteId == constructionSiteData.host then
      constructionSiteIndex = index
    end
  end

  if not constructionSiteIndex then
    return
  end

  local constructionSite = constructionSites[constructionSiteIndex]
  -- L17_2 = TriggerForAllMembers
  -- L18_2 = A0_2
  -- L19_2 = "17mov_constructionJob:refreshProgressValue"
  -- L20_2 = L16_2.progress
  -- L17_2(L18_2, L19_2, L20_2)
  -- break
  -- end
  -- end
  -- L11_2 = L0_1
  -- L11_2 = L11_2[L4_2]
  -- L11_2 = L11_2.builtPipes
  -- L11_2[L6_2] = true
end
local function installBlockOnWall(source, blockData, progressValue)
  local playerPed = GetPlayerPed(source)
  local playerCoords = GetEntityCoords(playerPed)
  local constructionSite = constructionSites[currentConstructionSiteIndex]

  if not constructionSite then
    return
  end

  local randomLocationName = constructionSite.randomLocation
  local wallIndex = blockData.wallIndex

  if wallIndex then
    local placeIndex = blockData.placeIndex
    if placeIndex then
      local jobLocation = Config.JobLocations[randomLocationName]
      local wall = jobLocation.walls[wallIndex]
      local blockLocation = wall.blocksInFrameLocations[placeIndex]
      local requiredProgress = blockLocation.progressValue

      if progressValue ~= requiredProgress then
        return
      end
    end
  end

  local targetCoords = vec3(Config.JobLocations[randomLocationName].walls[wallIndex].blocksInFrameLocations[placeIndex].coords.xyz)
  local distance = #(targetCoords - playerCoords)

  if distance > 12.0 then
    return
  end

  local currentConstructionSite = constructionSites[currentConstructionSiteIndex]
  local completedBlockInstallations = constructionSites[currentConstructionSiteIndex].completedBlockInstallations

  if not completedBlockInstallations then
    completedBlockInstallations = {}
  end

  currentConstructionSite.completedBlockInstallations = completedBlockInstallations

  if currentConstructionSite.completedBlockInstallations[blockData] then
    return
  end

  local blockedWalls = constructionSites[currentConstructionSiteIndex].blockedWalls
  local wallIsBlocked = blockedWalls[wallIndex]

  if wallIsBlocked then
    return
  end

  constructionSites[currentConstructionSiteIndex].completedBlockInstallations[blockData] = true

  TriggerForAllMembers(constructionSite.host, "17mov_constructionJob:installBlockOnWall_cl", blockData)

  local constructionSiteIndexToRemove = 0
  local pairsIterator = pairs(constructionSites)

  for index, siteData in pairsIterator do
    if siteData.host == constructionSite.host then
      local currentProgress = siteData.progress
      currentProgress = currentProgress + progressValue
      siteData.progress = currentProgress

      if siteData.progress > 100 then
        siteData.progress = 100
      end

      TriggerForAllMembers(constructionSite.host, "17mov_constructionJob:refreshProgressValue", siteData.progress)

      siteData.blockedWalls[wallIndex] = true
      constructionSiteIndexToRemove = index
      break
    end
  end

  Citizen.Wait(Config.WallBuildingTime)

  constructionSites[constructionSiteIndexToRemove].blockedWalls[wallIndex] = nil
end

local registerNetEvent = RegisterNetEvent
local weldingReadyEvent = "17mov_constructionJob:weldingReady"

registerNetEvent(weldingReadyEvent, installBlockOnWall)
local function handleWeldingCompletion(source, weldingId, progressValue)
  local jobLocations = ESX

  local jobLocationIndex = nil
  for index, jobLocationData in pairs(jobLocations) do
    local hostName = jobLocationData.host
    if A0_2 == hostName then
      jobLocationIndex = index
    end
  end

  if not jobLocationIndex then
    return
  end

  local randomLocation = ESX[jobLocationIndex].randomLocation

  if weldingId then
    local jobConfig = Config.JobLocations[randomLocation].welding[weldingId]
    local requiredProgress = jobConfig.progressValue

    if progressValue ~= requiredProgress then
      return
    end
  end

  local weldingTime = Config.WeldingTime * 0.8
  local currentTime = GetGameTimer()
  local lastWeldTime = LastWeldTime[source]

  if lastWeldTime then
    local elapsedTime = currentTime - lastWeldTime
    if weldingTime > elapsedTime then
      return
    end
  end

  LastWeldTime[source] = currentTime

  local weldingCoords = Config.JobLocations[randomLocation].welding[weldingId].coords
  local weldingPosition = vec3(weldingCoords.x, weldingCoords.y, weldingCoords.z)

  local playerPed = GetPlayerPed(source)
  local playerPosition = GetEntityCoords(playerPed)
  local distance = #(weldingPosition - playerPosition)

  if distance > 10.0 then
    return
  end

  local jobData = ESX[jobLocationIndex]
  local completedWeldings = ESX[jobLocationIndex].completedWeldings

  if not completedWeldings then
    completedWeldings = {}
  end

  jobData.completedWeldings = completedWeldings

  if jobData.completedWeldings[weldingId] then
    return
  end

  jobData.completedWeldings[weldingId] = true

  TriggerForAllMembers(A0_2, "17mov_constructionJob:disableWeldingBlip", weldingId)

  for index, jobLocationData in pairs(ESX) do
    local hostName = jobLocationData.host
    if A0_2 == hostName then
      local newProgress = jobLocationData.progress + progressValue
      jobLocationData.progress = newProgress

      if jobLocationData.progress > 100 then
        jobLocationData.progress = 100
      end

      TriggerForAllMembers(A0_2, "17mov_constructionJob:refreshProgressValue", jobLocationData.progress)
      break
    end
  end
end

RegisterNetEvent("17mov_construction:handleWeldingCompletion")
AddEventHandler("17mov_construction:handleWeldingCompletion", handleWeldingCompletion)

RegisterNetEvent("17mov_construction:endJob_sv")
AddEventHandler("17mov_construction:endJob_sv", function(A0_2, A1_2)
end)
local function endJobHandler(source)
  local playerSource = source
  local triggerForAllMembers = TriggerForAllMembers
  local playerSourceAlias = playerSource
  local endJobClientEvent = "17mov_construction:endJob_cl"
  local zeroValue = 0

  triggerForAllMembers(playerSourceAlias, endJobClientEvent, zeroValue)

  local pairsIterator = pairs
  local constructionSites = ConstructionSites

  for constructionSiteId, constructionSiteData in pairsIterator(constructionSites) do
    local hostId = constructionSiteData.host
    local playerSourceId = source

    if hostId == playerSourceId then
      local jobProgress = constructionSiteData.progress
      constructionSiteData.progress = 0

      local deleteEntity = DeleteEntity
      local networkGetEntityFromNetworkId = NetworkGetEntityFromNetworkId
      local mixerNetworkId = constructionSiteData.mixerNetId
      local mixerEntity = networkGetEntityFromNetworkId(mixerNetworkId)

      deleteEntity(mixerEntity)

      local objectNetworkId = ConstructionObjectNetworkId
      local constructionObjectEntity = networkGetEntityFromNetworkId(objectNetworkId)

      deleteEntity(constructionObjectEntity)

      constructionSiteData.working = false
      constructionSiteData.builtPipes = {}
      constructionSiteData.completedWeldings = {}
      constructionSiteData.completedBlockInstallations = {}
      constructionSiteData.completedCustomTasks = {}

      local clientsToReward = {}
      local startIndex = 1
      local numberOfClients = #constructionSiteData.clients
      local incrementStep = 1

      for i = startIndex, numberOfClients, incrementStep do
        local tableInsert = table.insert
        local clientToReward = constructionSiteData.clients[i]
        tableInsert(clientsToReward, clientToReward)
      end

      local tableInsert = table.insert
      tableInsert(clientsToReward, constructionSiteData.host)

      local onePercentWorth = Config.OnePercentWorth
      local baseReward = jobProgress * onePercentWorth

      local multiplyRewardWhileWorkingInGroup = Config.multiplyRewardWhileWorkingInGroup
      if multiplyRewardWhileWorkingInGroup then
        local floor = math.floor
        local numberOfParticipants = #constructionSiteData.clients + 1
        local totalReward = baseReward * numberOfParticipants
        baseReward = floor(totalReward)
      end

      local useModernUI = Config.useModernUI
      if useModernUI then
        local numberOfClientsInGroup = #constructionSiteData.clients
        if numberOfClientsInGroup == 0 then
          local recalculateRewards = RecalculateRewards
          local playerSourceForReward = playerSource
          recalculateRewards(playerSourceForReward)
        end
      end

      local individualRewards = {}
      local startIndexRewardLoop = 1
      local numberOfClientsToReward = #clientsToReward
      local incrementStepRewardLoop = 1

      for i = startIndexRewardLoop, numberOfClientsToReward, incrementStepRewardLoop do
        local individualReward = 0
        local useModernUIReward = Config.useModernUI
        if useModernUIReward then
          local letBossSplitReward = Config.letBossSplitReward
          if letBossSplitReward then
            local floorReward = math.floor
            local rewardOptions = constructionSiteData.rewardsOptions
            local clientId = clientsToReward[i]
            local rewardPercentage = rewardOptions[clientId] / 100
            local calculatedReward = baseReward * rewardPercentage
            individualReward = floorReward(calculatedReward)
          end
else
          local useModernUI = Config.useModernUI
          if not useModernUI then
            local splitReward = Config.splitReward
            if splitReward then
              local floor = math.floor
              local numberOfClients = #jobData.clients
              numberOfClients = numberOfClients + 1
              local rewardPerClient = rewardAmount / numberOfClients
              local roundedReward = floor(rewardPerClient)
              rewardAmount = roundedReward
          end
          else
            rewardAmount = rewardAmount
          end
        end
        if not bypassPenalty then
          local applyPenalty = PayPenalty
          local playerId = playerList[playerIndex]
          local penaltyAmount = Config.PenaltyAmount
          applyPenalty(playerId, penaltyAmount)
          local sendNotification = Notify
          local playerIdForNotification = playerList[playerIndex]
          local penaltyMessage = Config.Lang.penalty
          local totalPenaltyAmount = Config.PenaltyAmount
          penaltyMessage = penaltyMessage .. totalPenaltyAmount
          sendNotification(playerIdForNotification, penaltyMessage)
        end
        if not bypassPenalty then
          if bypassPenalty then
            goto continuePayment
          end
          local dontPayWithoutVehicle = Config.DontPayRewardWithoutVehicle
          if false ~= dontPayWithoutVehicle then
            goto continuePayment
          end
        end
        local createThread = CreateThread
        function processPayment()
          local playerIdentifier, playerListEntry, hasBeenPaid, paymentAmount, jobLocationData, paymentMultiplier
          local playerIndexForPayment = playerIndex
          local playerListForPayment = playerList
          local playerId = playerListForPayment[playerIndexForPayment]
          local paymentStatus = hasBeenPaidList
          local playerIdentifierForStatus = playerListForPayment[playerIndexForPayment]
          local playerHasBeenPaid = paymentStatus[playerIdentifierForStatus]
          if not playerHasBeenPaid then
            local playerIndexForPayment2 = playerIndex
            local playerListForPayment2 = playerList
            local playerId2 = playerListForPayment2[playerIndexForPayment2]
            local paymentStatus2 = hasBeenPaidList
            paymentStatus2[playerId2] = true
            local payPlayer = Pay
            local playerIndexForPayment3 = playerIndex
            local playerListForPayment3 = playerList
            local playerId3 = playerListForPayment3[playerIndexForPayment3]
            local finalRewardAmount = rewardAmount
            local jobLocations = Config.JobLocations
            local randomLocationName = jobData.randomLocation
            local jobLocation = jobLocations[randomLocationName]
            local paymentMultiplier = jobLocation.paymentMultipler
            if not paymentMultiplier then
              paymentMultiplier = 1.0
            end
            finalRewardAmount = finalRewardAmount * paymentMultiplier
            local numberOfPlayers = #playerList
            local jobName = currentJob
            payPlayer(playerId3, finalRewardAmount, numberOfPlayers, jobName)
            local sendRewardNotification = Notify
            local playerIndexForNotification = playerIndex
            local playerListForNotification = playerList
            local playerIdForNotification = playerListForNotification[playerIndexForNotification]
            local rewardMessage = Config.Lang.reward
            local finalRewardAmountForNotification = rewardAmount
            local jobLocations2 = Config.JobLocations
            local randomLocationName2 = jobData.randomLocation
            local jobLocation2 = jobLocations2[randomLocationName2]
            local paymentMultiplier2 = jobLocation2.paymentMultipler
            if not paymentMultiplier2 then
              paymentMultiplier2 = 1.0
            end
            finalRewardAmountForNotification = finalRewardAmountForNotification * paymentMultiplier2
            rewardMessage = rewardMessage .. finalRewardAmountForNotification
            sendRewardNotification(playerIdForNotification, rewardMessage)
          end
        end
        createThread(processPayment)
        ::continuePayment::
      end
      local numberOfClientsRemaining = #jobData.clients
      if 0 == numberOfClientsRemaining then
        esx[currentJob] = nil
        local triggerClientEvent = TriggerClientEvent
        local clearLobbyEvent = "17mov_construction:clearMyLobby"
        local jobCreatorSource = jobCreator
        triggerClientEvent(clearLobbyEvent, jobCreatorSource)
local cooldowns = {}
local lastCalledTime = 0
local cooldownDuration = 3000
local registerNetEvent = RegisterNetEvent

local startJobEventName = "17mov_construction:StartJob_sv"
registerNetEvent(startJobEventName)

local addEventHandler = AddEventHandler
local startJobEventHandler = "17mov_construction:StartJob_sv"

function startJobHandler()
  local playerSource = source
  local currentTime = GetGameTimer()
  local timeSinceLastCall = currentTime - lastCalledTime
  local cooldown = cooldownDuration

  if timeSinceLastCall <= cooldown then
    local notify = Notify
    local playerId = playerSource
    local language = Config.Lang
    local waitMessage = language.wait
    notify(playerId, waitMessage)
    return
  end

  lastCalledTime = currentTime
  local clients = nil
  local hostIndex = 0

  for index, teamData in pairs(Team) do
    local hostId = teamData.host
    if hostId == playerSource then
      clients = teamData.clients
      hostIndex = index
      break
    end
  end

  local requireJobForFriends = Config.RequireJobAlsoForFriends
  if requireJobForFriends then
    local requiredJob = Config.RequiredJob
    if "none" ~= requiredJob and clients ~= nil then
      local startIndex = 1
      local teamSize = #clients
      local increment = 1
      for i = startIndex, teamSize, increment do
        local getPlayerJob = GetPlayerJob
        local memberId = clients[i]
        local memberJob = getPlayerJob(memberId)
        local requiredJobConfig = Config.RequiredJob
        if memberJob ~= requiredJobConfig then
          local notify = Notify
          local playerId = playerSource
          local language = Config.Lang
          local notEverybodyHasRequiredJobMessage = language.notEverybodyHasRequiredJob
          notify(playerId, notEverybodyHasRequiredJobMessage)
          return
        end
      end
    end
  end

  local hasRequiredItem = IsHaveRequiredItem
  local playerId = playerSource
  local hasItem = hasRequiredItem(playerId)
  if not hasItem then
    local notify = Notify
    local playerId = playerSource
    local language = Config.Lang
    local dontHaveReqItemMessage = language.dontHaveReqItem
    notify(playerId, dontHaveReqItemMessage)
    return
  end

  local requireItemFromWholeTeam = Config.RequireItemFromWholeTeam
  if requireItemFromWholeTeam and clients ~= nil then
    local startIndex = 1
    local teamSize = #clients
    local increment = 1
    for i = startIndex, teamSize, increment do
      local hasRequiredItem = IsHaveRequiredItem
      local memberId = clients[i]
      local memberHasItem = hasRequiredItem(memberId)
      if not memberHasItem then
        local notify = Notify
        local playerId = playerSource
        local language = Config.Lang
        local dontHaveReqItemMessage = language.dontHaveReqItem
        notify(playerId, dontHaveReqItemMessage)
        return
      end
    end
  end

  local currentTimeOs = os.time()
  local getPlayerIdentifier = GetPlayerIdentifierByType
  local playerIdSource = playerSource
  local licenseType = "license"
  local playerLicense = getPlayerIdentifier(playerIdSource, licenseType)

  local jobCooldown = Config.JobCooldown
  if jobCooldown > 0 then
    local playerCooldown = cooldowns[playerLicense]
    if playerCooldown then
      local lastUsedTime = cooldowns[playerLicense]
      local timeSinceLastUsed = currentTimeOs - lastUsedTime
      local jobCooldownConfig = Config.JobCooldown
      if timeSinceLastUsed >= jobCooldownConfig then
        cooldowns[playerLicense] = nil
      else
        local remainingCooldown = jobCooldownConfig - timeSinceLastUsed
        local mathLib = math
      end
    end
  end
end

addEventHandler(startJobEventHandler, startJobHandler)
local floor = math.floor
        local remainingHours = remainingTime / 3600
        local hours = floor(remainingHours)
        local floorMath = math
        local floor2 = floorMath.floor
        local remainingMinutesSeconds = remainingTime % 3600
        local minutes = remainingMinutesSeconds / 60
        local minutesFloored = floor2(minutes)
        local seconds = remainingTime % 60
        local timeString = ""
        if hours > 0 then
          local tempString = timeString
          local hoursValue = hours
          local languageConfig = Config
          local hoursText = languageConfig.Lang.hours
          local space = " "
          tempString = tempString .. hoursValue .. hoursText .. space
          timeString = tempString
        end
        if minutesFloored > 0 then
          local tempString = timeString
          local minutesValue = minutesFloored
          local languageConfig = Config
          local minutesText = languageConfig.Lang.minutes
          local space = " "
          tempString = tempString .. minutesValue .. minutesText .. space
          timeString = tempString
        end
        local tempString = timeString
        local secondsValue = seconds
        local languageConfig = Config
        local secondsText = languageConfig.Lang.seconds
        tempString = tempString .. secondsValue .. secondsText
        timeString = tempString
        local notify = Notify
        local playerId = sourcePlayerId
        local stringFormat = string.format
        local languageConfig = Config
        local cooldownMessage = languageConfig.Lang.someoneIsOnCooldown
        local getPlayerIdentity = GetPlayerIdentity
        local sourcePlayer = sourcePlayerId
        local playerIdentity = getPlayerIdentity(sourcePlayer)
        local timeRemainingString = timeString
        local formattedMessage = stringFormat(cooldownMessage, playerIdentity, timeRemainingString)
        notify(playerId, formattedMessage)
        return
      end
    end
    if nil ~= targetPlayerIds then
      local index = 1
      local numberOfTargetPlayers = #targetPlayerIds
      local step = 1
      for i = index, numberOfTargetPlayers, step do
        local getPlayerIdentifierByType = GetPlayerIdentifierByType
        local targetPlayerId = targetPlayerIds[i]
        local identifierType = "license"
        local license = getPlayerIdentifierByType(targetPlayerId, identifierType)
        local cooldowns = jobCooldowns
        local cooldownData = cooldowns[license]
        if cooldownData then
          local cooldownTime = cooldownsTime
          local lastUsedTime = cooldownTime[license]
          local timeSinceLastUsed = currentTime - lastUsedTime
          local config = Config
          local jobCooldown = config.JobCooldown
          if timeSinceLastUsed >= jobCooldown then
            local cooldowns = jobCooldowns
            cooldowns[license] = nil
            local cooldownsTime = cooldownsTime
            cooldownsTime[license] = nil
          else
            local config = Config
            local jobCooldown = config.JobCooldown
            local remainingTime = jobCooldown - timeSinceLastUsed
            local floorMath = math
            local floor = floorMath.floor
            local remainingHours = remainingTime / 3600
            local hours = floor(remainingHours)
            local floorMath2 = math
            local floor2 = floorMath2.floor
            local remainingMinutesSeconds = remainingTime % 3600
            local minutes = remainingMinutesSeconds / 60
            local minutesFloored = floor2(minutes)
            local seconds = remainingTime % 60
            local timeString = ""
            if hours > 0 then
              local tempString = timeString
              local hoursValue = hours
              local languageConfig = Config
              local hoursText = languageConfig.Lang.hours
              local space = " "
              tempString = tempString .. hoursValue .. hoursText .. space
              timeString = tempString
            end
            if minutesFloored > 0 then
              local tempString = timeString
              local minutesValue = minutesFloored
              local languageConfig = Config
local function startConstructionJob(player, invitedPlayers, mixerCoords, cooldownDuration)
  local randomSeed = math
  randomSeed = randomSeed.randomseed
  local osTime = os
  osTime = osTime.time
  local year, month, day, hour, minute, second, wday, yday, isdst = osTime()
  randomSeed(year, month, day, hour, minute, second, wday, yday, isdst)

  local randomNumber = math
  randomNumber = randomNumber.random
  local minLocation = 1
  local maxLocation = #Config.JobLocations
  local randomLocationIndex = randomNumber(minLocation, maxLocation)

  local requireFriend = Config.RequireOneFriendMinimum
  if requireFriend then
    if invitedPlayers ~= nil then
      local numberOfInvitedPlayers = #invitedPlayers
      if numberOfInvitedPlayers > 0 then
        local esxPlayer = ESX[player]
        esxPlayer.working = true
        esxPlayer.randomLocation = randomLocationIndex
        esxPlayer.mixerCoords = mixerCoords

        TriggerForAllMembers(player, "17mov_construction:StartJob_cl", player, esxPlayer.randomLocation, #esxPlayer.clients + 1)

        Cooldowns[player] = true
        CooldownsTime[player] = cooldownDuration

        if invitedPlayers ~= nil then
          local start = 1
          local endValue = #invitedPlayers
          local increment = 1
          for i = start, endValue, increment do
            local getPlayerIdentifier = GetPlayerIdentifierByType
            local invitedPlayer = invitedPlayers[i]
            local licenseType = "license"
            local license = getPlayerIdentifier(invitedPlayer, licenseType)
            Cooldowns[license] = true
            CooldownsTime[license] = cooldownDuration
          end
        end
      else
        local notify = Notify
        local notificationSource = player
        local requireOneFriendMessage = Config.Lang.RequireOneFriend
        notify(notificationSource, requireOneFriendMessage)
      end
    else
      local notify = Notify
      local notificationSource = player
      local requireOneFriendMessage = Config.Lang.RequireOneFriend
      notify(notificationSource, requireOneFriendMessage)
    end
  else
    if invitedPlayers == nil then
      local tableInsert = table.insert
      local esxPlayers = ESX
      local playerInfo = {}
      playerInfo.host = player

      local cooldownRemaining = CooldownsTime[player]
          if cooldownRemaining then
            local formattedTime = ""
            local remainingMinutes = math.floor(cooldownRemaining / 60)
            local remainingSeconds = math.floor(cooldownRemaining % 60)

            if remainingMinutes > 0 then
              formattedTime = formattedTime .. remainingMinutes .. " " .. Config.Lang.minutes .. " "
            end

            formattedTime = formattedTime .. remainingSeconds .. Config.Lang.seconds

            local notify = Notify
            local notificationSource = player
            local formattedString = string.format
            local someoneIsOnCooldownMessage = Config.Lang.someoneIsOnCooldown
            local playerIdentity = GetPlayerIdentity(ESX.GetPlayerFromId(player))
            local remainingTime = formattedTime
            formattedString, someoneIsOnCooldownMessage, playerIdentity, remainingTime = formattedString(someoneIsOnCooldownMessage, playerIdentity, remainingTime)
            notify(notificationSource, formattedString, someoneIsOnCooldownMessage, playerIdentity, remainingTime)
            return
          end
        end
      end
    end
function startConstructionJob(randomLocation, cooldownTime, invitedPlayers, mixerCoords, constructionId)
  local clients = {}
  local blockedLicenses = {}

  local constructionData = {}
  constructionData.clients = clients
  constructionData.progress = 0
  local blockedWalls = {}
  constructionData.blockedWalls = blockedWalls
  constructions[constructionId] = constructionData

  for constructionIdIterator, constructionDataIterator in pairs(constructions) do
    local hostId = constructionDataIterator.host
    if hostId == randomLocation then
      constructionId = constructionIdIterator
    end
  end

  local construction = constructions[constructionId]
  construction.randomLocation = randomLocation
  construction.working = true
  construction.mixerCoords = mixerCoords

  TriggerForAllMembers(randomLocation, "17mov_construction:StartJob_cl", randomLocation, randomLocation, constructions[constructionId].randomLocation, #constructions[constructionId].clients + 1)

  constructionCooldowns[constructionId] = true
  constructionCooldownTimes[constructionId] = cooldownTime

  if invitedPlayers ~= nil then
    for i = 1, #invitedPlayers, 1 do
      local license = GetPlayerIdentifierByType(invitedPlayers[i], "license")
      blockedLicenses[license] = true
      constructionCooldownTimes[license] = cooldownTime
    end
  end
end

RegisterNetEvent(startConstructionJob, startConstructionJob)

function getConstructionTeam(playerId)
  local teamMembers = {}
  local playerList = {}
  local constructionId = 0

  for constructionIdIterator, constructionDataIterator in pairs(constructions) do
    local hostId = constructionDataIterator.host
    if playerId == hostId then
      constructionId = constructionIdIterator
      playerList = constructionDataIterator.clients
    end
  end

  if Config.useModernUI then
    for i = 1, #playerList, 1 do
      local teamMember = {}
      local memberId = playerList[i]
      teamMember.id = memberId
      local memberIdentity = GetPlayerIdentity(memberId)
      teamMember.name = memberIdentity
      teamMember.isHost = false
      local rewardOptions = constructions[constructionId].rewardsOptions
      local rewardPercent = rewardOptions[memberId]
      teamMember.rewardPercent = rewardPercent
      table.insert(teamMembers, teamMember)
    end

    if #playerList == 0 then
      local teamMember = {}
      teamMember.id = playerId
      local playerIdentity = GetPlayerIdentity(playerId)
      teamMember.name = playerIdentity
      teamMember.isHost = true
      local rewardOptions = constructions[constructionId].rewardsOptions
      local rewardPercent = rewardOptions[playerId]
      teamMember.rewardPercent = rewardPercent
      table.insert(teamMembers, teamMember)
    else
      local teamMember = {}
      teamMember.id = playerId
      local playerIdentity = GetPlayerIdentity(playerId)
      teamMember.name = playerIdentity
      teamMember.isHost = true
    end
  end
end
--[[
  Fonction pour obtenir tous les membres d'un groupe de construction.
  Elle prend en entrée l'ID du joueur hôte, une liste d'ID de joueurs et l'ID du joueur qui demande.
  Elle retourne une table contenant les informations de chaque membre du groupe.
]]
function getPartyMembers(playerId, playerList, requestingPlayerId)
  local partyMembers = {}

  if playerList == nil then
    local memberData = {}
    memberData.id = requestingPlayerId
    local playerName = GetPlayerIdentity(requestingPlayerId)
    memberData.name = playerName
    memberData.isHost = true
    table.insert(partyMembers, memberData)
    return partyMembers
  end

  if #playerList > 0 then
    for i = 1, #playerList, 1 do
      local memberData = {}
      local memberId = playerList[i]
      memberData.id = memberId
      local playerName = GetPlayerIdentity(memberId)
      memberData.name = playerName
      memberData.isHost = false
      table.insert(partyMembers, memberData)
    end

    local hostData = {}
    hostData.id = requestingPlayerId
    local hostName = GetPlayerIdentity(requestingPlayerId)
    hostData.name = hostName
    hostData.isHost = true
    table.insert(partyMembers, hostData)
  else
    local hostData = {}
    hostData.id = requestingPlayerId
    local hostName = GetPlayerIdentity(requestingPlayerId)
    hostData.name = hostName
    hostData.isHost = true
    table.insert(partyMembers, hostData)
  end

  return partyMembers
end

GetAllPartyMugs = getPartyMembers

--[[
  Fonction pour déclencher un événement sur tous les membres d'un groupe de construction.
  Elle prend en entrée l'ID du joueur hôte, le nom de l'événement, et des arguments optionnels.
  Elle parcourt la liste des clients du groupe et déclenche l'événement sur chacun d'eux.
]]
function TriggerForAllMembers(hostPlayerId, eventName, arg1, arg2, arg3, arg4)
  local partyClients = {}
  for _, constructionJob in pairs(ESX) do
    if hostPlayerId == constructionJob.host then
      partyClients = constructionJob.clients
    end
  end

  for i = 1, #partyClients + 1, 1 do
    local clientId = partyClients[i]
    if i > #partyClients then
      clientId = hostPlayerId
    end

    if clientId ~= nil then
      local clientType = type(clientId)
      if "number" == clientType then
        if "17mov_construction:RefreshMugs" == eventName then
          TriggerClientEvent(eventName, clientId, arg1, clientId, arg2, arg3)
        elseif "17mov_construction:StartJob_cl" == eventName then
          TriggerClientEvent(eventName, clientId, arg1, clientId, arg2, arg3, arg4)
        elseif "17mov_constructionJob:sendMixer_cl" == eventName then
          TriggerClientEvent(eventName, clientId, arg1, clientId, hostPlayerId)
        else
          TriggerClientEvent(eventName, clientId, arg1, arg2, arg3)
        end
      end
    end
  end
end

TriggerForAllMembers = TriggerForAllMembers

local registerEvent = RegisterNetEvent
local constructionData = {} -- Supposons que L0_1 stocke des données relatives à la construction
local playerVehicleNetIdEvent = "17mov_construction:SendVehicleNetId"

-- Enregistre l'événement pour envoyer l'ID réseau du véhicule
AddEventHandler(playerVehicleNetIdEvent, function(vehicleNetId)
  local sourcePlayerId = source
  for lobbyId, lobbyData in pairs(constructionData) do
    if lobbyData.host == sourcePlayerId then
      lobbyData.vehNetId = vehicleNetId
      break
    end
  end
end)

local playerDroppedEvent = "playerDropped"

-- Gère l'événement lorsqu'un joueur se déconnecte
AddEventHandler(playerDroppedEvent, function()
  local sourcePlayerId = source
  local lobbyStatus = "waiting"

  for lobbyId, lobbyData in pairs(constructionData) do
    if lobbyData.host == sourcePlayerId then
      -- Le joueur qui s'est déconnecté était l'hôte
      for i = 1, #lobbyData.clients do
        local clientPlayerId = lobbyData.clients[i]
        local clientPing = GetPlayerPing(clientPlayerId)

        if clientPing ~= 0 then
          -- Transférer l'hôte au premier client valide
          lobbyData.host = clientPlayerId
          Notify(clientPlayerId, Config.Lang.newBoss)
          lobbyData.clients[i] = nil
          lobbyStatus = lobbyId
          break
        end
      end
      lobbyStatus = lobbyId
      break
    end

    -- Le joueur qui s'est déconnecté était un client
    for i = 1, #lobbyData.clients do
      local clientPlayerId = lobbyData.clients[i]
      if clientPlayerId == sourcePlayerId then
        lobbyData.clients[i] = nil
        lobbyStatus = lobbyId
        break
      end
    end
  end

  if lobbyStatus == "waiting" then
    return
  end

  local hostPlayerId = constructionData[lobbyStatus].host
  local isWorking = constructionData[lobbyStatus].working

  if isWorking then
    -- La construction est en cours
    if #constructionData[lobbyStatus].clients == 0 then
      -- Plus de clients, nettoyer le lobby
      TriggerClientEvent("17mov_construction:clearMyLobby", hostPlayerId)
    else
      -- Rafraîchir les Mugs pour tous les membres
      TriggerForAllMembers(hostPlayerId, "17mov_construction:RefreshMugs", GetAllPartyMugs(hostPlayerId))

      if Config.useModernUI then
        -- Recalculer les récompenses
        RecalculateRewards(hostPlayerId)
      end
    end
  else
    -- La construction n'est pas en cours
    if #constructionData[lobbyStatus].clients == 0 then
      -- Plus de clients, nettoyer le lobby et supprimer les données
      TriggerClientEvent("17mov_construction:clearMyLobby", hostPlayerId)
      constructionData[lobbyStatus] = nil
    end
  end

  -- Supprimer le joueur de la liste des joueurs en attente (si présent)
  if waitingPlayers[sourcePlayerId] ~= nil then
    waitingPlayers[sourcePlayerId] = nil
  end

  -- Supprimer le joueur de la liste des joueurs en train de choisir un job (si présent)
  if choosingJobPlayers[sourcePlayerId] ~= nil then
    choosingJobPlayers[sourcePlayerId] = nil
  end
end)
local citizen = Citizen
local createThread = citizen.CreateThread

local function clearData(playerSource)
  local droppingWeapons = DroppingWeapons
  droppingWeapons = droppingWeapons[playerSource]
  if nil ~= droppingWeapons then
    droppingWeapons = DroppingWeapons
    droppingWeapons[playerSource] = nil
  end
  droppingWeapons = DroppingAmmo
  droppingWeapons = droppingWeapons[playerSource]
  if nil ~= droppingWeapons then
    droppingWeapons = DroppingAmmo
    droppingWeapons[playerSource] = nil
  end
  droppingWeapons = DroppingObjects
  droppingWeapons = droppingWeapons[playerSource]
  if nil ~= droppingWeapons then
    droppingWeapons = DroppingObjects
    droppingWeapons[playerSource] = nil
  end
end

createThread(clearData, 0)