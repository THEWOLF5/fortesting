local targetSystem

if Config.Framework == "QBCore" then
    targetSystem = "qb-target"
else
    targetSystem = "qtarget"
end

if GetResourceState("ox_target") ~= "missing" then
    targetSystem = "qtarget"    -- OX_Target have a backward compability to qtarget
end

function SpawnStartingPed()
    local pedModel = `a_m_y_genstreet_01`
    RequestModel(pedModel)
	while not HasModelLoaded(pedModel) do
		Citizen.Wait(50)
	end
    SpawnedPed = CreatePed(0, pedModel, Config.Locations.DutyToggle.Coords[1].x, Config.Locations.DutyToggle.Coords[1].y, Config.Locations.DutyToggle.Coords[1].z - 1.0, 92.59, false, true)
    FreezeEntityPosition(SpawnedPed, true)
    SetBlockingOfNonTemporaryEvents(SpawnedPed, true)
    SetEntityInvincible(SpawnedPed, true)
    exports[targetSystem]:AddTargetEntity(SpawnedPed, {
        options = {
            {
                event = "multiplayerConstruction:OpenMainMenu",
                icon = "fa-solid fa-handshake-simple",
                label = "Start Job",
                -- job = "RequiredJob",
                canInteract = function(entity)
                    local playerPed = PlayerPedId()
                    local pedCoords = GetEntityCoords(playerPed)
                    local dutyLocationCoords = vec3(Config.Locations.DutyToggle.Coords[1].x, Config.Locations.DutyToggle.Coords[1].y, Config.Locations.DutyToggle.Coords[1].z)
                    return #(pedCoords - dutyLocationCoords) < 5.0
                end
            },
        },
        distance = 2.5
    })
end

RegisterNetEvent("multiplayerConstruction:OpenMainMenu", function()
    OpenDutyMenu()
end)