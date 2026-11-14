---@class MechanicUpgradeLevel
---@field price integer
---@field grade? integer lowest job grade that may fit it, employee shops only
---@field materials? table<string, integer> cobalt_inventory items taken from the mechanic, employee shops only

---@class MechanicUpgrade
---@field slot integer
---@field toggle? boolean turbo is on or off rather than levelled
---@field levels MechanicUpgradeLevel[]

---@class MechanicService
---@field price integer
---@field system 'oil'|'battery'|'tyres'|'brakes'|'clutch'

return {
    -- Shops by id; the name on the blip and menus is shop.<id> in locales/en.json
    ---@type table<string, MechanicShop>
    shops = {
        lsc_burton = {
            job = 'mechanic', -- job that runs the shop and whose society account takes the money
            mode = 'employee', -- 'employee': staff customise and bill; 'self': owners customise and pay at checkout
            zone = { coords = vec3(-337.4, -136.9, 39.0), size = vec3(14.0, 18.0, 6.0), rotation = 340.0 }, -- work area: centre, size in meters, rotation
            duty = vec3(-347.0, -133.4, 39.0), -- staff point for duty and the shop account; employee shops only
            blip = { sprite = 72, colour = 3 }, -- blip sprite and colour ids; leave out for no blip
        },
        bennys = {
            job = 'bennys',
            mode = 'employee',
            zone = { coords = vec3(-211.6, -1324.6, 30.9), size = vec3(16.0, 14.0, 6.0), rotation = 0.0 },
            duty = vec3(-196.4, -1316.0, 31.1),
            blip = { sprite = 72, colour = 5 },
        },
        lsc_airport = {
            job = 'mechanic_lsia',
            mode = 'self',
            zone = { coords = vec3(-1155.0, -2007.0, 13.2), size = vec3(14.0, 14.0, 6.0), rotation = 315.0 },
            blip = { sprite = 72, colour = 0 },
        },
        lsc_lamesa = {
            job = 'mechanic_lamesa',
            mode = 'self',
            zone = { coords = vec3(731.8, -1088.9, 22.2), size = vec3(10.0, 14.0, 6.0), rotation = 0.0 },
            blip = { sprite = 72, colour = 0 },
        },
        beekers = {
            job = 'beeker',
            mode = 'self',
            zone = { coords = vec3(110.9, 6626.4, 31.8), size = vec3(12.0, 12.0, 6.0), rotation = 45.0 },
            blip = { sprite = 72, colour = 0 },
        },
    },

    -- Billing in employee shops
    billing = {
        maxMarkup = 50, -- highest markup a mechanic can add over list price, in percent
        mechanicShare = 0.5, -- share of the markup paid to the on-duty crew, 0.0 to 1.0; the rest goes to the shop account
        expireSeconds = 60, -- seconds the customer has to accept a bill
        customerRadius = 15.0, -- meters from the vehicle the customer must be to receive the bill
        crewRadius = 8.0, -- meters from the vehicle an on-duty mechanic must be to share the markup
    },

    -- List prices in dollars for cosmetic work
    prices = {
        paint = 800, -- a preset paint colour
        paintCustom = 1000, -- a custom RGB colour
        chameleon = 2500, -- a colour-shifting chameleon paint
        pearlescent = 600, -- the pearlescent layer over the paint
        wheelColour = 400, -- rim colour
        wheels = 1800, -- a new set of rims
        tyreSmoke = 350, -- tyre smoke colour
        tint = 350, -- window tint
        neon = 250, -- each neon kit or neon colour change
        xenon = 300, -- xenon headlights or their colour
        plate = 200, -- plate style
        livery = 500, -- a livery
        extra = 150, -- turning one vehicle extra on or off
        mod = { base = 600, step = 150 }, -- body mods: base price plus step for each level up
        ---@type table<integer, { base: integer, step: integer }>
        modSlots = { -- per mod slot overrides of mod: 0 spoiler, 1 front bumper, 2 rear bumper, 3 skirts, 4 exhaust, 5 frame, 7 hood, 10 roof, 14 horn
            [0] = { base = 1250, step = 600 },
            [1] = { base = 1000, step = 400 },
            [2] = { base = 1000, step = 400 },
            [3] = { base = 900, step = 300 },
            [4] = { base = 800, step = 250 },
            [5] = { base = 1500, step = 500 },
            [7] = { base = 1200, step = 400 },
            [10] = { base = 1100, step = 350 },
            [14] = { base = 300, step = 50 },
        },
    },

    -- Performance upgrades by mod slot; the menu name is upgrade.<name> in locales/en.json and each level's name is level.<name>.<level>
    ---@type table<string, MechanicUpgrade>
    upgrades = {
        engine = {
            slot = 11, -- GTA vehicle mod slot
            levels = { -- one entry per level: price in dollars, lowest job grade that may fit it, materials taken from the mechanic (employee shops)
                { price = 4500, materials = { steel = 2, oil = 1 } },
                { price = 9000, grade = 1, materials = { steel = 4, copper = 2, oil = 1 } },
                { price = 15000, grade = 2, materials = { steel = 6, copper = 4, electronickit = 1, oil = 2 } },
                { price = 25000, grade = 3, materials = { steel = 8, copper = 6, aluminum = 4, electronickit = 2, oil = 2 } },
            },
        },
        brakes = {
            slot = 12,
            levels = {
                { price = 2500, materials = { steel = 2, rubber = 2 } },
                { price = 5000, grade = 1, materials = { steel = 3, aluminum = 2, rubber = 2 } },
                { price = 9000, grade = 2, materials = { steel = 4, aluminum = 3, rubber = 3 } },
            },
        },
        transmission = {
            slot = 13,
            levels = {
                { price = 3500, materials = { steel = 3, oil = 1 } },
                { price = 7000, grade = 1, materials = { steel = 5, aluminum = 2, oil = 1 } },
                { price = 12000, grade = 2, materials = { steel = 6, aluminum = 3, electronickit = 1 } },
            },
        },
        suspension = {
            slot = 15,
            levels = {
                { price = 1500, materials = { steel = 2 } },
                { price = 3000, materials = { steel = 3, rubber = 1 } },
                { price = 5000, grade = 1, materials = { steel = 4, rubber = 2 } },
                { price = 8000, grade = 2, materials = { steel = 5, aluminum = 2, rubber = 2 } },
            },
        },
        armour = {
            slot = 16,
            levels = {
                { price = 3000, materials = { steel = 4 } },
                { price = 6000, materials = { steel = 6 } },
                { price = 10000, grade = 1, materials = { steel = 8 } },
                { price = 15000, grade = 2, materials = { steel = 10, aluminum = 2 } },
                { price = 22000, grade = 3, materials = { steel = 12, aluminum = 4 } },
            },
        },
        turbo = {
            slot = 18,
            toggle = true, -- on or off rather than levelled
            levels = {
                { price = 15000, grade = 2, materials = { steel = 3, aluminum = 2, electronickit = 1 } },
            },
        },
    },

    -- Repairs: dollars per percent of health restored, with a minimum charge; the name is repair.<part> in locales/en.json
    repairs = {
        engine = {
            perPercent = 20, -- dollars per percent of health restored
            minimum = 150, -- lowest charge in dollars
        },
        body = { perPercent = 12, minimum = 100 },
    },

    -- Services that reset a worn system to new; the name is service.<name> in locales/en.json
    ---@type table<string, MechanicService>
    services = {
        oil = {
            price = 200, -- dollars
            system = 'oil', -- wear system it resets: 'oil', 'battery', 'tyres', 'brakes' or 'clutch'
        },
        battery = { price = 600, system = 'battery' },
        tyres = { price = 800, system = 'tyres' },
        brakes = { price = 400, system = 'brakes' },
        clutch = { price = 900, system = 'clutch' },
    },

    -- Seconds a mechanic spends fitting each kind of line on a job
    fitting = {
        default = 5, -- any kind of line not listed below
        paint = 8, -- primary or secondary paint
        wheels = 6, -- wheel change
        mod = 6, -- cosmetic mod in a mod slot
        upgrade = 15, -- performance upgrade
        repair = 10, -- engine or body repair
        service = 6, -- service from services
    },

    -- Wear on owned vehicles
    wear = {
        reportSeconds = 15, -- seconds of driving the client batches before reporting distance
        perKm = { brakes = 0.02, clutch = 0.015, oil = 0.04, battery = 0.005, tyres = 0.015 }, -- condition percent lost per kilometer driven
        checkEngine = { oil = 25, battery = 20 }, -- condition percent under which the check-engine light comes on
    },

    -- Default keys; players can rebind them in GTA settings
    openKey = 'E', -- open the shop menu inside a shop zone
    pushKey = 'E', -- start and stop pushing a vehicle
}
