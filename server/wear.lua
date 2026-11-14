local config <const> = require 'config'
local db <const> = require 'server.db'

---@class MechanicWearRecord
---@field wear table<MechanicWearSystem, number> condition per system, 100 is new
---@field mileage integer meters when loaded
---@field pending integer meters driven since the last save
---@field dirty boolean
---@field lastSeen integer os.time of the last read or drive

local SYSTEMS <const> = { 'brakes', 'clutch', 'oil', 'battery', 'tyres' }
local MAX_METERS_PER_SECOND <const> = 120

local Wear <const> = {}

local UNOWNED_RECHECK_SECONDS <const> = 300
local IDLE_EVICT_SECONDS <const> = 600

---@type table<string, MechanicWearRecord>
local records <const> = {}

---@type table<string, integer> plate to the time it may be looked up again
local unowned <const> = {}

---@type table<integer, integer>
local lastReport <const> = {}

---@param status table?
---@return table<MechanicWearSystem, number>
local function readWear(status)
    local wear <const> = {}

    for _, system in ipairs(SYSTEMS) do
        local value <const> = type(status) == 'table' and tonumber(status[system])

        wear[system] = value and math.max(0, math.min(100, value)) or 100
    end

    return wear
end

---@param plate string
---@return MechanicWearRecord?
function Wear.get(plate)
    local record = records[plate]

    if record then
        record.lastSeen = os.time()
        return record
    end

    if (unowned[plate] or 0) > os.time() then return end

    local row <const> = db.getWear(plate)

    if not row then
        unowned[plate] = os.time() + UNOWNED_RECHECK_SECONDS
        return
    end

    unowned[plate] = nil

    local ok <const>, status <const> = pcall(json.decode, row.status or '{}')

    record = {
        wear = readWear(ok and status or nil),
        mileage = row.drivingdistance or 0,
        pending = 0,
        dirty = false,
        lastSeen = os.time(),
    }
    records[plate] = record

    return record
end

---@param record MechanicWearRecord
---@return boolean
local function needsCheckEngine(record)
    local limits <const> = config.wear.checkEngine

    return record.wear.oil < limits.oil or record.wear.battery < limits.battery
end

---@param entity integer
---@param record MechanicWearRecord
local function publish(entity, record)
    local state <const> = Entity(entity).state
    local checkEngine <const> = needsCheckEngine(record)

    if state.checkEngine ~= checkEngine then state:set('checkEngine', checkEngine, true) end
end

---@param plate string
---@param entity integer
---@param meters number
function Wear.drive(plate, entity, meters)
    local record <const> = Wear.get(plate)

    if not record then return end

    local km <const> = meters / 1000

    for system, perKm in pairs(config.wear.perKm) do
        record.wear[system] = math.max(0, record.wear[system] - perKm * km)
    end

    record.pending += math.floor(meters)
    record.dirty = true

    publish(entity, record)
end

---@param plate string
---@param system MechanicWearSystem
---@param entity? integer
function Wear.restore(plate, system, entity)
    local record <const> = Wear.get(plate)

    if not record then return end

    record.wear[system] = 100
    record.dirty = true

    if entity then publish(entity, record) end
end

---@param plates string[]
local function flush(plates)
    local saves <const> = {}

    for _, plate in ipairs(plates) do
        local record <const> = records[plate]

        if record?.dirty then
            saves[#saves + 1] = { plate = plate, status = json.encode(record.wear), meters = record.pending }
            record.dirty = false
        end
    end

    if #saves == 0 then return end

    local saved <const> = db.saveWear(saves)

    for _, save in ipairs(saves) do
        local record <const> = records[save.plate]

        if record and saved then
            record.mileage += save.meters
            record.pending -= save.meters
        elseif record then
            record.dirty = true
        end
    end
end

---@param plate string
function Wear.save(plate)
    flush({ plate })
end

local function pruneUnowned()
    local now <const> = os.time()

    for plate, recheckAt in pairs(unowned) do
        if recheckAt <= now then unowned[plate] = nil end
    end
end

function Wear.saveAll()
    local cutoff <const> = os.time() - IDLE_EVICT_SECONDS
    local plates <const> = {}

    for plate in pairs(records) do plates[#plates + 1] = plate end

    flush(plates)

    for _, plate in ipairs(plates) do
        local record <const> = records[plate]

        if record and not record.dirty and record.lastSeen < cutoff then records[plate] = nil end
    end

    pruneUnowned()
end

---@param entity integer
---@param ped integer
---@return boolean drove whether ped drives it, or drove it last and the seat is now empty
local function drove(entity, ped)
    local driver <const> = GetPedInVehicleSeat(entity, -1)

    if driver == ped then return true end

    return driver == 0 and GetLastPedInVehicleSeat(entity, -1) == ped
end

RegisterNetEvent('cobalt_mechanic:drove', function(netId, meters)
    local source <const> = source
    local now <const> = os.time()
    local elapsed <const> = now - (lastReport[source] or now - config.wear.reportSeconds)

    lastReport[source] = now

    if type(meters) ~= 'number' or meters ~= meters or meters <= 0 or elapsed <= 0 then return end

    local entity <const> = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)

    if entity == 0 or not drove(entity, GetPlayerPed(source)) then return end

    Wear.drive(db.plate(entity), entity, math.min(meters, elapsed * MAX_METERS_PER_SECOND))
end)

AddEventHandler('playerDropped', function()
    lastReport[source] = nil
end)

SetInterval(Wear.saveAll, 60000)

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then Wear.saveAll() end
end)

return Wear
