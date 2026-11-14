local config <const> = require 'config'
local Vehicle <const> = require 'client.vehicle'

local core <const> = exports.cobalt_core

local DICT <const>, CLIP <const> = 'missfinale_c2ig_11', 'pushcar_offcliff_m'
local UNPUSHABLE <const> = { [13] = true, [14] = true, [15] = true, [16] = true }

local pushing = false

---@return integer? vehicle a stalled car whose front or back the player stands at
local function stalledCar()
    if cache.vehicle then return end

    local coords <const> = GetEntityCoords(cache.ped)
    local vehicle <const> = lib.getClosestVehicle(coords, 4.0, false)

    if not vehicle or UNPUSHABLE[GetVehicleClass(vehicle)] or GetIsVehicleEngineRunning(vehicle) then return end
    if not IsVehicleSeatFree(vehicle, -1) then return end

    return vehicle
end

---@param vehicle integer
---@param key string the bound push key, shown on the prompt
local function push(vehicle, key)
    local min <const>, max <const> = GetModelDimensions(GetEntityModel(vehicle))
    local coords <const> = GetEntityCoords(cache.ped)
    local toFront <const> = #(GetOffsetFromEntityInWorldCoords(vehicle, 0.0, max.y, 0.0) - coords)
    local toBack <const> = #(GetOffsetFromEntityInWorldCoords(vehicle, 0.0, min.y, 0.0) - coords)
    local front <const> = toFront < toBack
    local bone <const> = GetPedBoneIndex(cache.ped, 6286)
    local y <const> = front and max.y + 0.1 or min.y - 0.3
    local z <const> = max.z + 1.0
    local heading <const> = front and 180.0 or 0.0

    AttachEntityToEntity(cache.ped, vehicle, bone, 0.0, y, z, 0.0, 0.0, heading, false, false, false, true, 0, true)

    lib.requestAnimDict(DICT)
    TaskPlayAnim(cache.ped, DICT, CLIP, 2.0, -8.0, -1, 35, 0, false, false, false)
    RemoveAnimDict(DICT)
    core:ShowTextUI(locale('prompt.stop_pushing'), { key = key })
    pushing = true

    CreateThread(function()
        while pushing and DoesEntityExist(vehicle) and NetworkHasControlOfEntity(vehicle) and not IsEntityDead(cache.ped) and not IsPedRagdoll(cache.ped) do
            if IsDisabledControlPressed(0, 34) then TaskVehicleTempAction(cache.ped, vehicle, 11, 1000) end
            if IsDisabledControlPressed(0, 9) then TaskVehicleTempAction(cache.ped, vehicle, 10, 1000) end

            SetVehicleForwardSpeed(vehicle, front and -1.0 or 1.0)

            if HasEntityCollidedWithAnything(vehicle) then SetVehicleOnGroundProperly(vehicle) end

            Wait(0)
        end

        pushing = false
        core:HideTextUI()
        DetachEntity(cache.ped, false, false)
        StopAnimTask(cache.ped, DICT, CLIP, 2.0)
    end)
end

---@param vehicle integer
---@return boolean
local function takeHold(vehicle)
    if not NetworkGetEntityIsNetworked(vehicle) or NetworkHasControlOfEntity(vehicle) then return true end

    return lib.callback.await('cobalt_mechanic:push', false, VehToNet(vehicle)) and Vehicle.control(vehicle)
end

---@param vehicle integer
---@param key string
local function tryPush(vehicle, key)
    if pushing then return end

    if not takeHold(vehicle) then
        core:Notify({ description = locale('errors.push_blocked'), type = 'error' })
        return
    end

    push(vehicle, key)
end

lib.addKeybind({
    name = 'cobalt_mechanic_push',
    description = locale('keybind.push'),
    defaultKey = config.pushKey,
    onPressed = function(self)
        if pushing then
            pushing = false
            return
        end

        if not IsControlPressed(0, 21) then return end

        local vehicle <const> = stalledCar()

        if vehicle then CreateThread(function() tryPush(vehicle, self:getCurrentKey()) end) end
    end,
})

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource or not pushing then return end

    pushing = false
    core:HideTextUI()
    DetachEntity(cache.ped, false, false)
    StopAnimTask(cache.ped, DICT, CLIP, 2.0)
end)
