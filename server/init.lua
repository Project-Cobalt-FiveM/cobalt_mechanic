local config <const> = require 'config'
local Fitting <const> = require 'server.fitting'
local Orders <const> = require 'server.orders'
local Sessions <const> = require 'server.sessions'
local Vehicles <const> = require 'server.vehicles'

local core <const> = exports.cobalt_core
local vehiclekeys <const> = exports.cobalt_vehiclekeys

local PUSH_RANGE <const> = 6.0
local PUSH_COOLDOWN_MS <const> = 3000

local lastPush <const> = {} ---@type table<integer, integer>

---@param source integer
---@param entity integer
---@return boolean
local function mayPush(source, entity)
    local plate <const> = Vehicles.plate(entity)
    local owner <const> = core:GetVehicleOwnerByPlate(plate)

    if not owner or owner == Sessions.citizenid(source) then return true end

    return vehiclekeys:HasKey(source, entity)
end

lib.callback.register('cobalt_mechanic:open', function(source, shopId, netId)
    return Sessions.open(source, shopId, netId)
end)

lib.callback.register('cobalt_mechanic:close', function(source, restored)
    local session <const> = Sessions.close(source, restored == true)

    if session then
        Fitting.abort(source)
        Orders.cancelFor(source)
    end

    return true
end)

lib.callback.register('cobalt_mechanic:push', function(source, netId)
    local entity <const> = Vehicles.fromNetId(netId)

    if not entity or GetPedInVehicleSeat(entity, -1) ~= 0 or GetIsVehicleEngineRunning(entity) then return false end
    if #(GetEntityCoords(GetPlayerPed(source)) - GetEntityCoords(entity)) > PUSH_RANGE then return false end

    local now <const> = GetGameTimer()

    if now - (lastPush[source] or -PUSH_COOLDOWN_MS) < PUSH_COOLDOWN_MS then return false end

    lastPush[source] = now

    if not mayPush(source, entity) then return false end

    Vehicles.allowControl(entity)

    return true
end)

lib.callback.register('cobalt_mechanic:quote', function(source, changes, markup)
    return Orders.quote(source, changes, markup)
end)

lib.callback.register('cobalt_mechanic:scan', function(source)
    local session <const> = Sessions.get(source)

    return session and { diagnosis = Sessions.diagnosis(session), balances = Sessions.balances(session) }
end)

lib.callback.register('cobalt_mechanic:nearby', function(source)
    local session <const> = Sessions.get(source)

    return { customers = session and Sessions.nearby(session) or {} }
end)

lib.callback.register('cobalt_mechanic:sendBill', function(source, data)
    return Orders.sendBill(source, data)
end)

lib.callback.register('cobalt_mechanic:checkout', function(source, changes, method)
    return Orders.checkout(source, changes, method)
end)

lib.callback.register('cobalt_mechanic:fitStep', function(source, id, index, completed)
    return Fitting.step(source, id, index, completed)
end)

lib.callback.register('cobalt_mechanic:answerBill', function(source, id, accept)
    return Orders.answerBill(source, id, accept)
end)

for id, shop in pairs(config.shops) do
    if not exports.cobalt_core:GetShared('Jobs', shop.job) then
        lib.print.warn(('shop %s pays into %s, which is not a job in cobalt_core'):format(id, shop.job))
    end
end

AddEventHandler('playerDropped', function()
    lastPush[source] = nil
end)
