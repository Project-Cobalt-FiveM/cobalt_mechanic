local Changes <const> = require 'shared.changes'
local db <const> = require 'server.db'
local Wear <const> = require 'server.wear'

local CONTROL_WINDOW_MS <const> = 3000

local Vehicles <const> = {}

---@param entity integer
function Vehicles.allowControl(entity)
    SetEntityIgnoreRequestControlFilter(entity, true)

    SetTimeout(CONTROL_WINDOW_MS, function()
        if DoesEntityExist(entity) then SetEntityIgnoreRequestControlFilter(entity, false) end
    end)
end

Vehicles.plate = db.plate

---@param netId any
---@return integer? entity
function Vehicles.fromNetId(netId)
    local entity <const> = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)

    if entity == 0 or GetEntityType(entity) ~= 2 then return end

    return entity
end

---@param entity integer
---@param parts ('engine'|'body'|'tyres')[]
local function fix(entity, parts)
    if #parts == 0 then return end

    local owner <const> = NetworkGetEntityOwner(entity)

    if owner > 0 then TriggerClientEvent('cobalt_mechanic:fix', owner, NetworkGetNetworkIdFromEntity(entity), parts) end
end

---@param plate string
---@return table props the saved look of an owned vehicle, without damage, fuel or dirt
function Vehicles.savedMods(plate)
    local ok <const>, props <const> = pcall(json.decode, db.getMods(plate) or '{}')

    if not ok or type(props) ~= 'table' then return {} end

    return Changes.cosmetic(props)
end

---Fits the props on the car, saves them when the car is owned, and runs repairs and services.
---@param entity integer
---@param props table
---@param repairs? ('engine'|'body')[]
---@param services? MechanicWearSystem[]
---@return boolean saved
function Vehicles.apply(entity, props, repairs, services)
    local plate <const> = Vehicles.plate(entity)
    local saved = false

    if next(props) then
        Entity(entity).state:set('ox_lib:setVehicleProperties', props, true)
        saved = db.mergeMods(plate, props)
    end

    fix(entity, repairs or {})

    for _, system in ipairs(services or {}) do
        Wear.restore(plate, system, entity)

        if system == 'tyres' then fix(entity, { 'tyres' }) end
    end

    Wear.save(plate)

    return saved
end

return Vehicles
