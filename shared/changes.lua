local config <const> = require 'config'

local colours <const> = lib.load('data.colours') --[[@as MechanicColour[] ]]
local chameleons <const> = lib.load('data.chameleons') --[[@as MechanicChameleon[] ]]
local cosmetics <const> = lib.load('data.cosmetics')

---@alias MechanicPaintSlot 'primary'|'secondary'
---@alias MechanicFinish 'normal'|'metallic'|'pearl'|'matte'|'metal'|'chrome'
---@alias MechanicRgb [integer, integer, integer]

---@alias MechanicChangeKind
---| 'paint' | 'paintCustom' | 'pearlescent' | 'wheelColour' | 'wheels' | 'tyreSmoke' | 'tint' | 'neon'
---| 'xenon' | 'plate' | 'livery' | 'extra' | 'mod' | 'upgrade' | 'repair' | 'service'

---@class MechanicChange
---@field kind MechanicChangeKind
---@field slot? MechanicPaintSlot|integer
---@field index? integer
---@field rgb? MechanicRgb
---@field finish? MechanicFinish
---@field type? integer
---@field custom? boolean
---@field enabled? boolean|boolean[]
---@field colour? integer
---@field legacy? boolean
---@field id? integer
---@field name? string
---@field level? integer
---@field part? string

---@class MechanicLine
---@field key string one line per key; a later change with the same key replaces the earlier one
---@field label string
---@field price integer
---@field props? table ox_lib vehicle properties the change sets
---@field repair? 'engine'|'body'
---@field service? string wear system the change restores
---@field grade? integer
---@field materials? table<string, integer>

---@class MechanicHealth
---@field engine number 0 to 100
---@field body number 0 to 100

local CART_LIMIT <const> = 40

local FINISHES <const> = { normal = 0, metallic = 1, pearl = 2, matte = 3, metal = 4, chrome = 5 }

local NON_COSMETIC <const> = {
    'plate', 'lockState', 'bodyHealth', 'engineHealth', 'tankHealth', 'fuelLevel', 'oilLevel', 'dirtLevel',
    'windows', 'doors', 'tyres',
}

local UPGRADE_KEYS <const> = {
    [11] = 'modEngine',
    [12] = 'modBrakes',
    [13] = 'modTransmission',
    [15] = 'modSuspension',
    [16] = 'modArmor',
    [18] = 'modTurbo',
}

---@generic T
---@param list T[]
---@param field string
---@return table<any, T>
local function indexBy(list, field)
    local map <const> = {}

    for _, entry in ipairs(list) do map[entry[field]] = entry end

    return map
end

local colourByIndex <const> = indexBy(colours, 'index')
local chameleonByIndex <const> = indexBy(chameleons, 'index')
local tintByLevel <const> = indexBy(cosmetics.tints, 'level')
local xenonByIndex <const> = indexBy(cosmetics.xenons, 'index')
local plateByIndex <const> = indexBy(cosmetics.plates, 'index')
local wheelTypeById <const> = indexBy(cosmetics.wheelTypes, 'id')
local modBySlot <const> = indexBy(cosmetics.mods, 'slot')

---@param value any
---@param min integer
---@param max integer
---@return integer?
local function int(value, min, max)
    local number <const> = type(value) == 'number' and math.tointeger(value)

    if not number or number < min or number > max then return end

    return number
end

---@param value any
---@return MechanicRgb?
local function rgb(value)
    if type(value) ~= 'table' then return end

    local r <const>, g <const>, b <const> = int(value[1], 0, 255), int(value[2], 0, 255), int(value[3], 0, 255)

    if not r or not g or not b then return end

    return { r, g, b }
end

---@param slot any
---@return MechanicPaintSlot?
local function paintSlot(slot)
    if slot == 'primary' or slot == 'secondary' then
        return slot
    end
end

---@param slot MechanicPaintSlot
---@return string colourKey, string typeKey
local function paintKeys(slot)
    if slot == 'primary' then
        return 'color1', 'paintType1'
    end

    return 'color2', 'paintType2'
end

---@param rgb MechanicRgb
---@return string
local function hexOf(rgb)
    return ('#%02X%02X%02X'):format(rgb[1], rgb[2], rgb[3])
end

---@param base { base: integer, step: integer }
---@param index integer
---@return integer
local function stepped(base, index)
    return base.base + base.step * math.max(index, 0)
end

---@param health number
---@param repair { perPercent: integer, minimum: integer }
---@return integer
local function repairPrice(health, repair)
    return math.max(repair.minimum, math.ceil((100 - health) * repair.perPercent))
end

---@param upgrade MechanicUpgrade
---@param level integer
---@return boolean|integer value the ox_lib property value for that level
local function upgradeValue(upgrade, level)
    if upgrade.toggle then
        return level > 0
    end

    return level - 1
end

---@param name string
---@param level integer
---@return string
local function upgradeLabel(name, level)
    if level > 0 then
        return locale(('level.%s.%d'):format(name, level))
    end

    return locale('line.stock', locale('upgrade.' .. name):lower())
end

---@type table<string, fun(change: MechanicChange, health: MechanicHealth): MechanicLine?>
local resolvers <const> = {}

function resolvers.paint(change)
    local slot <const> = paintSlot(change.slot)
    local index <const> = int(change.index, 0, 242)

    if not slot or not index then return end

    local colour <const> = colourByIndex[index] or chameleonByIndex[index]

    if not colour then return end

    local colourKey <const> = paintKeys(slot)
    local chameleon <const> = chameleonByIndex[index] ~= nil

    return {
        key = 'paint:' .. slot,
        label = locale(slot == 'primary' and 'line.paint_primary' or 'line.paint_secondary', colour.name),
        price = chameleon and config.prices.chameleon or config.prices.paint,
        props = { [colourKey] = index },
    }
end

function resolvers.paintCustom(change)
    local slot <const> = paintSlot(change.slot)
    local colour <const> = rgb(change.rgb)
    local finish <const> = FINISHES[change.finish]

    if not slot or not colour or not finish then return end

    local colourKey <const>, typeKey <const> = paintKeys(slot)

    return {
        key = 'paint:' .. slot,
        label = locale(slot == 'primary' and 'line.custom_primary' or 'line.custom_secondary', hexOf(colour)),
        price = config.prices.paintCustom,
        props = { [colourKey] = colour, [typeKey] = finish },
    }
end

function resolvers.pearlescent(change)
    local colour <const> = colourByIndex[int(change.index, 0, 159) or -1]

    if not colour then return end

    return {
        key = 'pearlescent',
        label = locale('line.pearlescent', colour.name),
        price = config.prices.pearlescent,
        props = { pearlescentColor = colour.index },
    }
end

function resolvers.wheelColour(change)
    local colour <const> = colourByIndex[int(change.index, 0, 159) or -1]

    if not colour then return end

    return {
        key = 'wheelColour',
        label = locale('line.rim_colour', colour.name),
        price = config.prices.wheelColour,
        props = { wheelColor = colour.index },
    }
end

function resolvers.wheels(change)
    local wheelType <const> = wheelTypeById[int(change.type, 0, 12) or -1]
    local index <const> = int(change.index, -1, 255)

    if not wheelType or not index then return end

    local custom <const> = change.custom == true

    return {
        key = 'wheels',
        label = index < 0 and locale('line.stock_rims') or locale('line.rims', locale('wheel.' .. wheelType.id), index + 1),
        price = config.prices.wheels,
        props = {
            wheels = wheelType.id,
            modFrontWheels = index,
            modBackWheels = wheelType.id == 6 and index or nil,
            modCustomTiresF = custom,
            modCustomTiresR = custom,
        },
    }
end

function resolvers.tyreSmoke(change)
    local colour <const> = rgb(change.rgb)

    if not colour then return end

    return {
        key = 'tyreSmoke',
        label = locale('line.tyre_smoke', hexOf(colour)),
        price = config.prices.tyreSmoke,
        props = { modSmokeEnabled = true, tyreSmokeColor = colour },
    }
end

function resolvers.tint(change)
    local tint <const> = tintByLevel[int(change.index, 0, 6) or -1]

    if not tint then return end

    return {
        key = 'tint',
        label = locale('line.tint', locale('tint.' .. tint.level)),
        price = config.prices.tint,
        props = { windowTint = tint.level },
    }
end

function resolvers.neon(change)
    local enabled <const> = change.enabled

    if type(enabled) ~= 'table' or #enabled ~= 4 then return end

    local strips <const> = {}

    for i = 1, 4 do
        if type(enabled[i]) ~= 'boolean' then return end

        strips[i] = enabled[i]
    end

    local colour <const> = cosmetics.neons[int(change.colour, 1, #cosmetics.neons) or 0]

    if not colour then return end

    return {
        key = 'neon',
        label = locale('line.neon', locale('neon.' .. colour.id)),
        price = config.prices.neon,
        props = { neonEnabled = strips, neonColor = colour.rgb },
    }
end

function resolvers.xenon(change)
    if change.enabled == false then
        return {
            key = 'xenon',
            label = locale('line.halogen'),
            price = config.prices.xenon,
            props = { modXenon = false },
        }
    end

    local xenon <const> = xenonByIndex[int(change.colour, 0, 255) or -1]

    if not xenon then return end

    return {
        key = 'xenon',
        label = locale('line.xenon', locale('xenon.' .. xenon.index)),
        price = config.prices.xenon,
        props = { modXenon = true, xenonColor = xenon.index },
    }
end

function resolvers.plate(change)
    local plate <const> = plateByIndex[int(change.index, 0, 12) or -1]

    if not plate then return end

    return {
        key = 'plate',
        label = locale('line.plate', locale('plate.' .. plate.index)),
        price = config.prices.plate,
        props = { plateIndex = plate.index },
    }
end

function resolvers.livery(change)
    local index <const> = int(change.index, -1, 63)

    if not index then return end

    return {
        key = 'livery',
        label = index < 0 and locale('line.no_livery') or locale('line.livery', index + 1),
        price = config.prices.livery,
        props = change.legacy and { livery = index } or { modLivery = index },
    }
end

function resolvers.extra(change)
    local id <const> = int(change.id, 1, 20)

    if not id or type(change.enabled) ~= 'boolean' then return end

    return {
        key = 'extra:' .. id,
        label = locale(change.enabled and 'line.extra_on' or 'line.extra_off', id),
        price = config.prices.extra,
        props = { extras = { [tostring(id)] = change.enabled and 0 or 1 } },
    }
end

function resolvers.mod(change)
    local mod <const> = modBySlot[int(change.slot, 0, 49) or -1]
    local index <const> = int(change.index, -1, 255)

    if not mod or not index then return end

    local name <const> = locale('mod.' .. mod.slot)

    return {
        key = 'mod:' .. mod.slot,
        label = index < 0 and locale('line.stock', name:lower()) or locale('line.mod', name, index + 1),
        price = stepped(config.prices.modSlots[mod.slot] or config.prices.mod, index),
        props = { [mod.key] = index },
    }
end

function resolvers.upgrade(change)
    local upgrade <const> = config.upgrades[change.name]

    if not upgrade then return end

    local level <const> = int(change.level, 0, #upgrade.levels)

    if not level then return end

    local key <const> = UPGRADE_KEYS[upgrade.slot]
    local entry <const> = upgrade.levels[level]

    return {
        key = 'upgrade:' .. change.name,
        label = upgradeLabel(change.name, level),
        price = entry?.price or 0,
        props = { [key] = upgradeValue(upgrade, level) },
        grade = entry and entry.grade,
        materials = entry and entry.materials,
    }
end

function resolvers.repair(change, health)
    local repair <const> = config.repairs[change.part]
    local current <const> = health[change.part]

    if not repair or not current or current >= 99.5 then return end

    return {
        key = 'repair:' .. change.part,
        label = locale('line.repair', locale('repair.' .. change.part), math.floor(current)),
        price = repairPrice(current, repair),
        repair = change.part,
    }
end

function resolvers.service(change)
    local service <const> = config.services[change.name]

    if not service then return end

    return {
        key = 'service:' .. change.name,
        label = locale('service.' .. change.name),
        price = service.price,
        service = service.system,
    }
end

local Changes <const> = {}

---@param entity integer
---@return MechanicHealth
function Changes.health(entity)
    return {
        engine = math.max(0, math.min(100, GetVehicleEngineHealth(entity) / 10)),
        body = math.max(0, math.min(100, GetVehicleBodyHealth(entity) / 10)),
    }
end

---@param change any
---@param health MechanicHealth
---@return MechanicLine?
function Changes.resolve(change, health)
    if type(change) ~= 'table' then return end

    local resolver <const> = resolvers[change.kind]

    return resolver and resolver(change, health)
end

---@param changes any
---@param health MechanicHealth
---@return MechanicLine[]? lines in cart order, one per key
---@return string? error
function Changes.resolveAll(changes, health)
    if type(changes) ~= 'table' or #changes == 0 then
        return nil, locale('errors.cart_empty')
    end

    if #changes > CART_LIMIT then
        return nil, locale('errors.cart_full')
    end

    local lines <const>, positions <const> = {}, {}

    for _, change in ipairs(changes) do
        local line <const> = Changes.resolve(change, health)

        if not line then
            return nil, locale('errors.cart_stale')
        end

        local position <const> = positions[line.key]

        if position then
            lines[position] = line
        else
            lines[#lines + 1] = line
            positions[line.key] = #lines
        end
    end

    return lines
end

---@param lines MechanicLine[]
---@return table props
function Changes.props(lines)
    local props <const> = {}

    for _, line in ipairs(lines) do
        for key, value in pairs(line.props or {}) do
            if key == 'extras' and props.extras then
                for id, state in pairs(value) do props.extras[id] = state end
            else
                props[key] = key == 'extras' and table.clone(value) or value
            end
        end
    end

    return props
end

---@param props table ox_lib vehicle properties
---@return table props the same table without plate text, locks, damage, fuel or dirt
function Changes.cosmetic(props)
    for _, key in ipairs(NON_COSMETIC) do props[key] = nil end

    return props
end

---@param lines MechanicLine[]
---@return integer
function Changes.total(lines)
    local total = 0

    for _, line in ipairs(lines) do total += line.price end

    return total
end

---@param lines MechanicLine[]
---@return table<string, integer>
function Changes.materials(lines)
    local needed <const> = {}

    for _, line in ipairs(lines) do
        for item, count in pairs(line.materials or {}) do needed[item] = (needed[item] or 0) + count end
    end

    return needed
end

---@param lines MechanicLine[]
---@return integer
function Changes.requiredGrade(lines)
    local grade = 0

    for _, line in ipairs(lines) do grade = math.max(grade, line.grade or 0) end

    return grade
end

return Changes
