local config <const> = require 'config'
local Changes <const> = require 'shared.changes'
local Staff <const> = require 'server.staff'
local Vehicles <const> = require 'server.vehicles'
local Wear <const> = require 'server.wear'

local core <const> = exports.cobalt_core
local banking <const> = exports.cobalt_banking

local VEHICLE_RANGE <const> = 12.0

---@class MechanicSession
---@field source integer
---@field shopId string
---@field shop MechanicShop
---@field shopLabel string
---@field entity integer
---@field netId integer
---@field plate string
---@field citizenid string
---@field ownerCid? string
---@field wasFrozen boolean the car was frozen before the session froze it

local Sessions <const> = {}

---@type table<integer, MechanicSession>
local open <const> = {}

---@param citizenid string?
---@return string?
local function nameOf(citizenid)
    return citizenid and core:GetName(citizenid)
end

---@param source integer
---@return string?
function Sessions.citizenid(source)
    return core:GetPlayer(source)?.PlayerData.citizenid
end

---@param source integer
---@return string
function Sessions.playerName(source)
    return nameOf(Sessions.citizenid(source)) or GetPlayerName(source)
end

---@param shop MechanicShop
---@param coords vector3
---@return boolean
local function insideShop(shop, coords)
    local size <const> = shop.zone.size
    local reach <const> = math.max(size.x, size.y) / 2 + 4.0

    return #(coords.xy - shop.zone.coords.xy) <= reach and math.abs(coords.z - shop.zone.coords.z) <= size.z
end

---@param session MechanicSession
---@return boolean
function Sessions.inRange(session)
    if not DoesEntityExist(session.entity) then return false end

    local ped <const> = GetPlayerPed(session.source)

    return ped ~= 0 and #(GetEntityCoords(ped) - GetEntityCoords(session.entity)) <= VEHICLE_RANGE
end

---@param session MechanicSession
function Sessions.diagnosis(session)
    local health <const> = Changes.health(session.entity)
    local record <const> = Wear.get(session.plate)

    return {
        mileageKm = record and math.floor((record.mileage + record.pending) / 1000) or 0,
        scannedAt = os.time() * 1000,
        engine = health.engine,
        body = health.body,
        wear = record?.wear or nil,
    }
end

---@param session MechanicSession
---@return { bank: integer, cash: integer }?
function Sessions.balances(session)
    if session.shop.mode ~= 'self' then return end

    local player <const> = core:GetPlayer(session.source)

    return {
        bank = banking:GetBalance(session.citizenid),
        cash = player and player.Functions.GetMoney('cash') or 0,
    }
end

---@param source integer
---@param shopId any
---@param netId any
---@return table? view
---@return string? error
function Sessions.open(source, shopId, netId)
    local shop <const> = config.shops[shopId]
    local entity <const> = Vehicles.fromNetId(netId)
    local citizenid <const> = Sessions.citizenid(source)
    local ped <const> = GetPlayerPed(source)

    if not shop or not entity or not citizenid or ped == 0 then
        return nil, locale('errors.no_car')
    end

    if not insideShop(shop, GetEntityCoords(entity)) then
        return nil, locale('errors.outside_shop')
    end

    if #(GetEntityCoords(ped) - GetEntityCoords(entity)) > VEHICLE_RANGE then
        return nil, locale('errors.too_far')
    end

    local plate <const> = Vehicles.plate(entity)
    local ownerCid <const> = core:GetVehicleOwnerByPlate(plate)
    local shopLabel <const> = locale('shop.' .. shopId)

    if shop.mode == 'employee' and not Staff.onDutyJob(source, shop.job) then
        return nil, locale('errors.staff_only', shopLabel)
    end

    if shop.mode == 'self' and ownerCid ~= citizenid then
        return nil, locale('errors.owner_only')
    end

    for other, session in pairs(open) do
        if other ~= source and session.entity == entity then
            return nil, locale('errors.car_taken')
        end
    end

    if not DoesEntityExist(entity) or open[source] then
        return nil, locale('errors.no_car')
    end

    ---@type MechanicSession
    local session <const> = {
        source = source,
        shopId = shopId,
        shop = shop,
        shopLabel = shopLabel,
        entity = entity,
        netId = NetworkGetNetworkIdFromEntity(entity),
        plate = plate,
        citizenid = citizenid,
        ownerCid = ownerCid,
        wasFrozen = IsEntityPositionFrozen(entity),
    }

    open[source] = session
    FreezeEntityPosition(entity, true)
    Vehicles.allowControl(entity)

    return {
        mode = shop.mode,
        shop = {
            label = shopLabel,
            maxMarkup = config.billing.maxMarkup,
            mechanicShare = config.billing.mechanicShare,
        },
        vehicle = { plate = plate, owner = nameOf(ownerCid) },
        me = {
            name = Sessions.playerName(source),
            grade = shop.mode == 'employee' and Staff.grade(source, shop.job) or 0,
            canBillShop = shop.mode == 'employee' and Staff.canBillShop(source, shop.job),
        },
        balances = Sessions.balances(session),
        diagnosis = Sessions.diagnosis(session),
    }
end

---@param source integer
---@return MechanicSession?
function Sessions.get(source)
    local session <const> = open[source]

    if not session or not Sessions.inRange(session) then return end

    return session
end

---@param session MechanicSession
local function unfreeze(session)
    if session.wasFrozen or not DoesEntityExist(session.entity) then return end

    FreezeEntityPosition(session.entity, false)
end

---@param session MechanicSession
local function restoreLook(session)
    local props <const> = Vehicles.savedMods(session.plate)

    if not next(props) or not DoesEntityExist(session.entity) then return end

    Entity(session.entity).state:set('ox_lib:setVehicleProperties', props, true)
end

---@param source integer
---@param restored boolean the client put the car back the way it was before the session
---@return MechanicSession?
function Sessions.close(source, restored)
    local session <const> = open[source]

    if not session then return end

    open[source] = nil
    unfreeze(session)

    if not restored and session.ownerCid then restoreLook(session) end

    return session
end

---@param session MechanicSession
---@return boolean
function Sessions.isCurrent(session)
    return open[session.source] == session and Sessions.inRange(session)
end

---@param session MechanicSession
---@return { id: integer, name: string, distance: number, isOwner: boolean }[]
function Sessions.nearby(session)
    local coords <const> = GetEntityCoords(session.entity)
    local customers <const> = {}

    for _, nearby in ipairs(lib.getNearbyPlayers(coords, config.billing.customerRadius)) do
        local player <const> = nearby.id
        local citizenid <const> = player ~= session.source and Sessions.citizenid(player)

        if citizenid then
            customers[#customers + 1] = {
                id = player,
                name = nameOf(citizenid) or GetPlayerName(player),
                distance = math.floor(#(nearby.coords - coords)),
                isOwner = citizenid == session.ownerCid,
            }
        end
    end

    table.sort(customers, function(a, b) return a.distance < b.distance end)

    return customers
end

AddEventHandler('playerDropped', function()
    Sessions.close(source, false)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    for _, session in pairs(open) do unfreeze(session) end
end)

return Sessions
