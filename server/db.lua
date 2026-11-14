---@class MechanicWearRow
---@field status? string
---@field drivingdistance? integer

local db <const> = {}

local SELECT_WEAR <const> = 'SELECT status, drivingdistance FROM player_vehicles WHERE plate = ?'
local SELECT_MODS <const> = 'SELECT mods FROM player_vehicles WHERE plate = ?'
local MERGE_MODS <const> = 'UPDATE player_vehicles SET mods = JSON_MERGE_PATCH(COALESCE(mods, \'{}\'), ?) WHERE plate = ?'
local SAVE_WEAR <const> = [[
    UPDATE player_vehicles
    SET status = JSON_MERGE_PATCH(COALESCE(status, '{}'), ?), drivingdistance = COALESCE(drivingdistance, 0) + ?
    WHERE plate = ?
]]

---@param entity integer
---@return string plate the vehicle's plate without surrounding spaces, as player_vehicles keys it
function db.plate(entity)
    return (GetVehicleNumberPlateText(entity):gsub('^%s+', ''):gsub('%s+$', ''))
end

---@param plate string
---@return MechanicWearRow? row nil when no player owns the vehicle
function db.getWear(plate)
    return MySQL.single.await(SELECT_WEAR, { plate })
end

---@param plate string
---@return string? mods the saved ox_lib properties as JSON
function db.getMods(plate)
    return MySQL.scalar.await(SELECT_MODS, { plate })
end

---@param plate string
---@param props table
---@return boolean
function db.mergeMods(plate, props)
    return MySQL.update.await(MERGE_MODS, { json.encode(props), plate }) == 1
end

---@class MechanicWearSave
---@field plate string
---@field status string the wear table as JSON
---@field meters integer

---@param saves MechanicWearSave[]
---@return boolean
function db.saveWear(saves)
    local queries <const> = {}

    for i, save in ipairs(saves) do
        queries[i] = { query = SAVE_WEAR, values = { save.status, save.meters, save.plate } }
    end

    return MySQL.transaction.await(queries) == true
end

return db
