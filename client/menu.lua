local config <const> = require 'config'
local Camera <const> = require 'client.camera'
local Changes <const> = require 'shared.changes'
local Vehicle <const> = require 'client.vehicle'

local core <const> = exports.cobalt_core

---@param entries table[] cosmetics entries, each named by `<group>.<entry[idField]>` in the locales
---@param group string
---@param idField string
---@return table[]
local function named(entries, group, idField)
    for _, entry in ipairs(entries) do entry.name = locale(('%s.%s'):format(group, entry[idField])) end

    return entries
end

local catalog <const> = {
    colours = lib.load('data.colours'),
    chameleons = lib.load('data.chameleons'),
    prices = {},
    services = {},
    repairs = {},
}

do
    local cosmetics <const> = lib.load('data.cosmetics')

    catalog.tints = named(cosmetics.tints, 'tint', 'level')
    catalog.neons = named(cosmetics.neons, 'neon', 'id')
    catalog.xenons = named(cosmetics.xenons, 'xenon', 'index')
    catalog.plates = named(cosmetics.plates, 'plate', 'index')

    for key, price in pairs(config.prices) do
        if type(price) == 'number' then catalog.prices[key] = price end
    end

    for name, service in pairs(config.services) do
        catalog.services[#catalog.services + 1] = {
            name = name,
            label = locale('service.' .. name),
            price = service.price,
            system = service.system,
        }
    end

    for part, repair in pairs(config.repairs) do
        catalog.repairs[part] = { perPercent = repair.perPercent, minimum = repair.minimum }
    end

    table.sort(catalog.services, function(a, b) return a.price < b.price end)
end

---@class MechanicClientSession
---@field shopId string
---@field vehicle integer
---@field baseline table

local Menu <const> = {}

---@type MechanicClientSession?
local session

local opening = false

---@type integer?
local openBill

---@type { id: integer, index: integer }?
local fitting

---@type table<string, string>?
local uiStrings

---@return table<string, string>
local function uiLocales()
    if uiStrings then return uiStrings end

    local strings <const> = {}

    for key, value in pairs(lib.getLocales()) do
        if key:sub(1, 3) == 'ui.' then strings[key] = value end
    end

    uiStrings = strings

    return strings
end

---@param action string
---@param data? any
---@param locales? table<string, string>
local function send(action, data, locales)
    SendNUIMessage({ action = action, data = data, locales = locales })
end

local function refocus()
    local focused <const> = (session ~= nil and not fitting) or openBill ~= nil

    SetNuiFocus(focused, focused)
end

---@param target table
---@param props table
local function merge(target, props)
    for key, value in pairs(props) do
        if key == 'extras' then
            target.extras = target.extras or {}

            for id, state in pairs(value) do target.extras[tonumber(id)] = state end
        else
            target[key] = value
        end
    end
end

---@param vehicle integer
---@param changes any
---@return table props
local function previewProps(vehicle, changes)
    if type(changes) ~= 'table' or #changes == 0 then
        return {}
    end

    local lines <const> = Changes.resolveAll(changes, Changes.health(vehicle))

    return lines and Changes.props(lines) or {}
end

---@param changes any
local function preview(changes)
    if not session or not Vehicle.control(session.vehicle) then return end

    local props <const> = previewProps(session.vehicle, changes)

    lib.setVehicleProperties(session.vehicle, session.baseline)

    if next(props) then lib.setVehicleProperties(session.vehicle, props) end
end

---@return boolean
function Menu.isOpen()
    return session ~= nil or opening
end

---@param shopId string
---@param vehicle integer
---@return boolean
function Menu.open(shopId, vehicle)
    if session or opening or not DoesEntityExist(vehicle) then return false end

    opening = true

    local view <const>, err <const> = lib.callback.await('cobalt_mechanic:open', false, shopId, VehToNet(vehicle))

    if not view then
        opening = false
        core:Notify({ description = err or locale('errors.cannot_work'), type = 'error' })
        return false
    end

    if not Vehicle.control(vehicle) then
        lib.callback.await('cobalt_mechanic:close', false, true)
        opening = false
        core:Notify({ description = locale('errors.held_elsewhere'), type = 'error' })
        return false
    end

    session = { shopId = shopId, vehicle = vehicle, baseline = Vehicle.baseline(vehicle) }
    opening = false

    view.vehicle.label = Vehicle.label(vehicle)
    view.props = Vehicle.summary(session.baseline)
    view.options = Vehicle.options(vehicle)
    view.stats = Vehicle.stats(vehicle)
    view.catalog = catalog

    Camera.start(vehicle)
    send('open', view, uiLocales())
    refocus()

    local opened <const> = session

    CreateThread(function()
        while session == opened do
            Wait(1000)

            if session == opened and (not DoesEntityExist(vehicle) or IsEntityDead(cache.ped)) then Menu.close() end
        end
    end)

    return true
end

function Menu.close()
    if not session then return end

    local closing <const> = session

    if fitting then core:cancelProgress() end

    session, fitting = nil, nil

    local restored <const> = DoesEntityExist(closing.vehicle) and Vehicle.control(closing.vehicle)

    if restored then lib.setVehicleProperties(closing.vehicle, closing.baseline) end

    Camera.stop()
    send('close')
    refocus()
    TriggerEvent('cobalt_mechanic:closed')
    lib.callback.await('cobalt_mechanic:close', false, restored)
end

---@param name string
---@param handler fun(data: table): any
local function on(name, handler)
    RegisterNUICallback(name, function(data, cb)
        cb(handler(type(data) == 'table' and data or {}) or {})
    end)
end

on('close', function()
    if fitting then
        return { ok = false }
    end

    if session then Menu.close() end

    return { ok = true }
end)

on('preview', function(data)
    if not session then
        return { stats = {} }
    end

    preview(data.changes)

    return { stats = Vehicle.stats(session.vehicle) }
end)

on('quote', function(data)
    return lib.callback.await('cobalt_mechanic:quote', false, data.changes, data.markup)
end)

on('camera', function(data)
    Camera.view(data.view)
    return { ok = true }
end)

on('orbit', function(data)
    Camera.orbit(tonumber(data.dx) or 0, tonumber(data.dy) or 0)
    return { ok = true }
end)

on('zoom', function(data)
    Camera.zoom(tonumber(data.delta) or 0)
    return { ok = true }
end)

on('scan', function()
    local result <const> = lib.callback.await('cobalt_mechanic:scan', false)

    return { diagnosis = result?.diagnosis }
end)

on('nearby', function()
    return lib.callback.await('cobalt_mechanic:nearby', false)
end)

on('sendBill', function(data)
    if not session then
        return { ok = false, error = locale('errors.away_from_car') }
    end

    return lib.callback.await('cobalt_mechanic:sendBill', false, data)
end)

on('checkout', function(data)
    return lib.callback.await('cobalt_mechanic:checkout', false, data.changes, data.method)
end)

on('answerBill', function(data)
    local result <const> = lib.callback.await('cobalt_mechanic:answerBill', false, data.id, data.accept == true)
        or { ok = false, error = locale('errors.bill_failed') }

    openBill = nil
    refocus()

    if not result.ok then core:Notify({ description = result.error, type = 'error' }) end

    return result
end)

RegisterNetEvent('cobalt_mechanic:applied', function(props)
    if not session or type(props) ~= 'table' then return end
    merge(session.baseline, props)
    preview({})

    local result <const> = lib.callback.await('cobalt_mechanic:scan', false)

    if not session then return end

    send('refresh', {
        props = Vehicle.summary(session.baseline),
        diagnosis = result?.diagnosis,
        balances = result?.balances,
        stats = Vehicle.stats(session.vehicle),
    })
end)

---@param id integer
---@param index integer
---@param item { label: string, seconds: integer }
local function fitStep(id, index, item)
    local done <const> = core:Progressbar({
        label = locale('progress.fitting', item.label),
        duration = item.seconds * 1000,
        canCancel = true,
        anim = { dict = 'mini@repair', clip = 'fixing_a_player', flag = 1 },
        disable = { move = true, car = true, combat = true },
    })

    lib.callback.await('cobalt_mechanic:fitStep', false, id, index, done == true)
end

RegisterNetEvent('cobalt_mechanic:fitting', function(state)
    if not session then return end

    send('fitting', state)

    if not state then
        fitting = nil
        refocus()
        return
    end

    local item <const> = state.items[state.index]

    if not item or (fitting and fitting.id == state.id and fitting.index == state.index) then return end

    fitting = { id = state.id, index = state.index }
    refocus()
    CreateThread(function() fitStep(state.id, state.index, item) end)
end)

RegisterNetEvent('cobalt_mechanic:billStatus', function(status)
    if session then send('billStatus', status) end
end)

RegisterNetEvent('cobalt_mechanic:bill', function(bill)
    if session then return end

    local entity <const> = NetworkDoesNetworkIdExist(bill.netId) and NetworkGetEntityFromNetworkId(bill.netId) or 0

    bill.vehicle = entity ~= 0 and Vehicle.label(entity) or bill.plate
    openBill = bill.id
    send('bill', bill, uiLocales())
    refocus()
end)

RegisterNetEvent('cobalt_mechanic:billCancelled', function(id)
    send('billCancelled', id)

    if id ~= openBill then return end

    openBill = nil
    refocus()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource or not session or not NetworkHasControlOfEntity(session.vehicle) then return end

    lib.setVehicleProperties(session.vehicle, session.baseline)
end)

return Menu
