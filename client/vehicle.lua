local config <const> = require 'config'
local Changes <const> = require 'shared.changes'

local inventory <const> = exports.cobalt_inventory

local cosmetics <const> = lib.load('data.cosmetics')

local UPGRADE_ORDER <const> = { 'engine', 'brakes', 'transmission', 'suspension', 'armour', 'turbo' }

local UPGRADE_KEYS <const> = {
    engine = 'modEngine',
    brakes = 'modBrakes',
    transmission = 'modTransmission',
    suspension = 'modSuspension',
    armour = 'modArmor',
    turbo = 'modTurbo',
}

local CONTROL_TIMEOUT_MS <const> = 1500

local Vehicle <const> = {}

---@param vehicle integer
---@return boolean
function Vehicle.control(vehicle)
    if NetworkHasControlOfEntity(vehicle) then return true end

    NetworkRequestControlOfEntity(vehicle)

    return pcall(lib.waitFor, function() return NetworkHasControlOfEntity(vehicle) or nil end, nil, CONTROL_TIMEOUT_MS)
end

---@param vehicle integer
---@param slot integer
---@param index integer
---@param fallback string
---@return string
local function modName(vehicle, slot, index, fallback)
    local label <const> = GetModTextLabel(vehicle, slot, index)
    local text <const> = label and GetLabelText(label)

    if not text or text == 'NULL' or text == '' then
        return fallback
    end

    return text
end

---@param vehicle integer
---@param slot integer
---@param name string
---@return string[]
local function modOptions(vehicle, slot, name)
    local options <const> = {}

    for index = 0, GetNumVehicleMods(vehicle, slot) - 1 do
        options[#options + 1] = modName(vehicle, slot, index, locale('vehicle.option', name, index + 1))
    end

    return options
end

---@param vehicle integer
---@return table[]
local function wheelOptions(vehicle)
    local isBike <const> = GetVehicleClass(vehicle) == 8
    local originalType <const> = GetVehicleWheelType(vehicle)
    local originalMod <const> = GetVehicleMod(vehicle, 23)
    local originalCustom <const> = GetVehicleModVariation(vehicle, 23)
    local wheels <const> = {}

    for _, wheelType in ipairs(cosmetics.wheelTypes) do
        if (wheelType.id == 6) == isBike then
            SetVehicleWheelType(vehicle, wheelType.id)

            local name <const> = locale('wheel.' .. wheelType.id)
            local options <const> = modOptions(vehicle, 23, name)

            if #options > 0 then
                wheels[#wheels + 1] = { type = wheelType.id, name = name, options = options }
            end
        end
    end

    SetVehicleWheelType(vehicle, originalType)
    SetVehicleMod(vehicle, 23, originalMod, originalCustom)

    return wheels
end

---@param vehicle integer
---@return { legacy: boolean, options: string[] }
local function liveryOptions(vehicle)
    local name <const> = locale('vehicle.livery')
    local modded <const> = modOptions(vehicle, 48, name)

    if #modded > 0 then
        return { legacy = false, options = modded }
    end

    local options <const> = {}

    for index = 0, GetVehicleLiveryCount(vehicle) - 1 do
        local text <const> = GetLabelText(GetLiveryName(vehicle, index) or '')

        options[#options + 1] = (text ~= 'NULL' and text ~= '') and text or locale('vehicle.option', name, index + 1)
    end

    return { legacy = true, options = options }
end

---@param materials table<string, integer>?
---@return { item: string, label: string, count: integer }[]
local function materialList(materials)
    local list <const> = {}

    for item, count in pairs(materials or {}) do
        local label <const> = inventory:GetItemDef(item)?.label or item

        list[#list + 1] = { item = item, label = label, count = count }
    end

    table.sort(list, function(a, b) return a.label < b.label end)

    return list
end

---@param vehicle integer
---@return table[]
local function upgradeOptions(vehicle)
    local upgrades <const> = {}

    for _, name in ipairs(UPGRADE_ORDER) do
        local upgrade <const> = config.upgrades[name]
        local fitted <const> = upgrade.toggle and #upgrade.levels or GetNumVehicleMods(vehicle, upgrade.slot)
        local available <const> = math.min(fitted, #upgrade.levels)
        local levels <const> = {}

        for level = 1, available do
            local entry <const> = upgrade.levels[level]

            levels[level] = {
                name = locale(('level.%s.%d'):format(name, level)),
                price = entry.price,
                grade = entry.grade or 0,
                materials = materialList(entry.materials),
            }
        end

        if #levels > 0 then
            upgrades[#upgrades + 1] = {
                name = name,
                label = locale('upgrade.' .. name),
                toggle = upgrade.toggle == true,
                levels = levels,
            }
        end
    end

    return upgrades
end

---@param vehicle integer
---@return table
function Vehicle.options(vehicle)
    SetVehicleModKit(vehicle, 0)

    local mods <const> = {}

    for _, mod in ipairs(cosmetics.mods) do
        local name <const> = locale('mod.' .. mod.slot)
        local options <const> = modOptions(vehicle, mod.slot, name)

        if #options > 0 then
            mods[#mods + 1] = {
                slot = mod.slot,
                name = name,
                group = mod.group,
                price = config.prices.modSlots[mod.slot] or config.prices.mod,
                options = options,
            }
        end
    end

    local extras <const> = {}

    for id = 1, 20 do
        if DoesExtraExist(vehicle, id) then extras[#extras + 1] = id end
    end

    return {
        mods = mods,
        wheels = wheelOptions(vehicle),
        liveries = liveryOptions(vehicle),
        extras = extras,
        upgrades = upgradeOptions(vehicle),
    }
end

---@param vehicle integer
---@return table baseline every cosmetic and performance property, without damage or fuel
function Vehicle.baseline(vehicle)
    return Changes.cosmetic(lib.getVehicleProperties(vehicle) or {})
end

---@param props table
---@return table
function Vehicle.summary(props)
    local mods <const>, upgrades <const>, extras <const> = {}, {}, {}

    for _, mod in ipairs(cosmetics.mods) do mods[tostring(mod.slot)] = props[mod.key] or -1 end

    for id, state in pairs(props.extras or {}) do extras[tostring(id)] = state end

    for name, key in pairs(UPGRADE_KEYS) do
        local value <const> = props[key]

        upgrades[name] = type(value) == 'boolean' and (value and 1 or 0) or (value or -1) + 1
    end

    return {
        color1 = props.color1,
        color2 = props.color2,
        pearlescentColor = props.pearlescentColor,
        wheelColor = props.wheelColor,
        wheels = props.wheels,
        modFrontWheels = props.modFrontWheels,
        modCustomTiresF = props.modCustomTiresF == true,
        modSmokeEnabled = props.modSmokeEnabled == true,
        tyreSmokeColor = props.tyreSmokeColor,
        windowTint = props.windowTint,
        neonEnabled = props.neonEnabled,
        neonColor = props.neonColor,
        modXenon = props.modXenon == true,
        xenonColor = props.xenonColor,
        plateIndex = props.plateIndex,
        livery = props.livery,
        modLivery = props.modLivery,
        extras = extras,
        mods = mods,
        upgrades = upgrades,
    }
end

---@param vehicle integer
---@param slot integer
---@return number percent the fitted mod adds, 0 when stock
local function modifier(vehicle, slot)
    local index <const> = GetVehicleMod(vehicle, slot)

    if index < 0 then
        return 0
    end

    return GetVehicleModModifierValue(vehicle, slot, index) / 100
end

---@param value number
---@return number
local function score(value)
    return math.floor(math.max(0, math.min(10, value * 10)) * 10 + 0.5) / 10
end

---@param vehicle integer
---@return MechanicStats
function Vehicle.stats(vehicle)
    local class <const> = GetVehicleClass(vehicle)
    local turbo <const> = IsToggleModOn(vehicle, 18) and 0.1 or 0
    local drivetrain <const> = (modifier(vehicle, 11) + modifier(vehicle, 13)) / 2
    local acceleration <const> = GetVehicleAcceleration(vehicle) * (1 + drivetrain + turbo)
    local braking <const> = GetVehicleMaxBraking(vehicle) * (1 + modifier(vehicle, 12))
    local traction <const> = GetVehicleMaxTraction(vehicle)
    local handling <const> = traction * (1 + modifier(vehicle, 15) / 2)
    local armour <const> = GetVehicleMod(vehicle, 16)

    return {
        topSpeed = math.floor(GetVehicleEstimatedMaxSpeed(vehicle) * 3.6 * (1 + modifier(vehicle, 11) / 10) + 0.5),
        acceleration = score(acceleration / math.max(GetVehicleClassMaxAcceleration(class), 0.01)),
        braking = score(braking / math.max(GetVehicleClassMaxBraking(class), 0.01)),
        handling = score(handling / math.max(GetVehicleClassMaxTraction(class), 0.01)),
        traction = score(traction / math.max(GetVehicleClassMaxTraction(class), 0.01)),
        armour = (armour + 1) * 20,
    }
end

---@param vehicle integer
---@return string
function Vehicle.label(vehicle)
    local model <const> = GetEntityModel(vehicle)
    local make <const> = GetLabelText(GetMakeNameFromVehicleModel(model))
    local name <const> = GetLabelText(GetDisplayNameFromVehicleModel(model))

    if make == 'NULL' or make == '' then
        return name
    end

    return ('%s %s'):format(make, name)
end

RegisterNetEvent('cobalt_mechanic:fix', function(netId, parts)
    local vehicle <const> = NetworkGetEntityFromNetworkId(netId)

    if vehicle == 0 or not NetworkHasControlOfEntity(vehicle) then return end

    for _, part in ipairs(parts) do
        if part == 'body' then
            local engine <const> = GetVehicleEngineHealth(vehicle)

            SetVehicleFixed(vehicle)
            SetVehicleDeformationFixed(vehicle)
            SetVehicleEngineHealth(vehicle, engine)
        elseif part == 'engine' then
            SetVehicleEngineHealth(vehicle, 1000.0)
            SetVehiclePetrolTankHealth(vehicle, 1000.0)
        elseif part == 'tyres' then
            for wheel = 0, 7 do SetVehicleTyreFixed(vehicle, wheel) end
        end
    end
end)

return Vehicle
