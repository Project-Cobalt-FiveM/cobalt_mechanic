---@class MechanicTint
---@field level integer named by `tint.<level>` in the locales
---@field hex string

---@class MechanicNeonColour
---@field id string named by `neon.<id>` in the locales
---@field rgb [integer, integer, integer]

---@class MechanicXenon
---@field index integer named by `xenon.<index>` in the locales
---@field hex string

---@class MechanicPlate
---@field index integer named by `plate.<index>` in the locales

---@class MechanicWheelType
---@field id integer named by `wheel.<id>` in the locales

---@class MechanicModSlot
---@field slot integer named by `mod.<slot>` in the locales
---@field key string ox_lib vehicle property
---@field group 'exterior'|'interior'|'engine'

return {
    ---@type MechanicTint[]
    tints = {
        { level = 0, hex = '#E5E5E5' },
        { level = 3, hex = '#7A7A7A' },
        { level = 2, hex = '#2E2E2E' },
        { level = 5, hex = '#1A1A1A' },
        { level = 1, hex = '#0A0A0A' },
        { level = 6, hex = '#1F4A2A' },
    },

    ---@type MechanicNeonColour[]
    neons = {
        { id = 'white', rgb = { 255, 255, 255 } },
        { id = 'blue', rgb = { 2, 21, 255 } },
        { id = 'electric', rgb = { 3, 144, 255 } },
        { id = 'mint', rgb = { 0, 255, 140 } },
        { id = 'lime', rgb = { 94, 255, 1 } },
        { id = 'yellow', rgb = { 255, 255, 0 } },
        { id = 'orange', rgb = { 255, 128, 0 } },
        { id = 'red', rgb = { 255, 0, 0 } },
        { id = 'pink', rgb = { 255, 20, 147 } },
        { id = 'hot_pink', rgb = { 255, 5, 190 } },
        { id = 'purple', rgb = { 138, 43, 226 } },
        { id = 'violet', rgb = { 64, 0, 255 } },
    },

    ---@type MechanicXenon[]
    xenons = {
        { index = 255, hex = '#DCE6F0' },
        { index = 0, hex = '#FFFFFF' },
        { index = 1, hex = '#1F66E0' },
        { index = 2, hex = '#0390FF' },
        { index = 3, hex = '#00FF8C' },
        { index = 4, hex = '#5EFF01' },
        { index = 5, hex = '#FFFF00' },
        { index = 6, hex = '#FFD24C' },
        { index = 7, hex = '#FF8000' },
        { index = 8, hex = '#FF0000' },
        { index = 9, hex = '#FF1493' },
        { index = 10, hex = '#FF05BE' },
        { index = 11, hex = '#8A2BE2' },
        { index = 12, hex = '#4000FF' },
    },

    ---@type MechanicPlate[]
    plates = {
        { index = 0 },
        { index = 3 },
        { index = 4 },
        { index = 1 },
        { index = 2 },
        { index = 5 },
        { index = 6 },
        { index = 7 },
        { index = 8 },
        { index = 9 },
        { index = 10 },
        { index = 11 },
        { index = 12 },
    },

    ---@type MechanicWheelType[]
    wheelTypes = {
        { id = 0 },
        { id = 1 },
        { id = 2 },
        { id = 3 },
        { id = 4 },
        { id = 5 },
        { id = 7 },
        { id = 8 },
        { id = 9 },
        { id = 10 },
        { id = 11 },
        { id = 12 },
        { id = 6 },
    },

    ---@type MechanicModSlot[]
    mods = {
        { slot = 0, key = 'modSpoilers', group = 'exterior' },
        { slot = 1, key = 'modFrontBumper', group = 'exterior' },
        { slot = 2, key = 'modRearBumper', group = 'exterior' },
        { slot = 3, key = 'modSideSkirt', group = 'exterior' },
        { slot = 4, key = 'modExhaust', group = 'exterior' },
        { slot = 5, key = 'modFrame', group = 'exterior' },
        { slot = 6, key = 'modGrille', group = 'exterior' },
        { slot = 7, key = 'modHood', group = 'exterior' },
        { slot = 8, key = 'modFender', group = 'exterior' },
        { slot = 9, key = 'modRightFender', group = 'exterior' },
        { slot = 10, key = 'modRoof', group = 'exterior' },
        { slot = 25, key = 'modPlateHolder', group = 'exterior' },
        { slot = 26, key = 'modVanityPlate', group = 'exterior' },
        { slot = 37, key = 'modTrunk', group = 'exterior' },
        { slot = 42, key = 'modArchCover', group = 'exterior' },
        { slot = 43, key = 'modAerials', group = 'exterior' },
        { slot = 44, key = 'modTrimB', group = 'exterior' },
        { slot = 45, key = 'modTank', group = 'exterior' },
        { slot = 46, key = 'modWindows', group = 'exterior' },
        { slot = 14, key = 'modHorns', group = 'interior' },
        { slot = 27, key = 'modTrimA', group = 'interior' },
        { slot = 28, key = 'modOrnaments', group = 'interior' },
        { slot = 29, key = 'modDashboard', group = 'interior' },
        { slot = 30, key = 'modDial', group = 'interior' },
        { slot = 31, key = 'modDoorSpeaker', group = 'interior' },
        { slot = 32, key = 'modSeats', group = 'interior' },
        { slot = 33, key = 'modSteeringWheel', group = 'interior' },
        { slot = 34, key = 'modShifterLeavers', group = 'interior' },
        { slot = 35, key = 'modAPlate', group = 'interior' },
        { slot = 36, key = 'modSpeakers', group = 'interior' },
        { slot = 38, key = 'modHydrolic', group = 'engine' },
        { slot = 39, key = 'modEngineBlock', group = 'engine' },
        { slot = 40, key = 'modAirFilter', group = 'engine' },
        { slot = 41, key = 'modStruts', group = 'engine' },
    },
}
