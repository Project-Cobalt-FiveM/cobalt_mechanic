local config <const> = require 'config'
local Menu <const> = require 'client.menu'

local core <const> = exports.cobalt_core
local management <const> = exports.cobalt_management

---@type string?
local currentShop

local promptShown = false

---@param job string
---@return boolean
local function onDutyFor(job)
    local current <const> = management:GetJob()

    return current?.name == job and current.onduty == true
end

---@return boolean
local function canSelfServe()
    local shop <const> = currentShop and config.shops[currentShop]

    return shop ~= nil and shop.mode == 'self' and cache.vehicle and cache.seat == -1 and not Menu.isOpen()
end

---@type fun()
local updatePrompt

local openKeybind <const> = lib.addKeybind({
    name = 'cobalt_mechanic_open',
    description = locale('keybind.customise'),
    defaultKey = config.openKey,
    onPressed = function()
        if not canSelfServe() then return end

        promptShown = false
        core:HideTextUI()

        if not Menu.open(currentShop --[[@as string]], cache.vehicle --[[@as integer]]) then updatePrompt() end
    end,
})

function updatePrompt()
    local show <const> = canSelfServe()

    if show == promptShown then return end

    promptShown = show

    if show then
        core:ShowTextUI(locale('prompt.customise'), { key = openKeybind:getCurrentKey() })
    else
        core:HideTextUI()
    end
end

lib.onCache('vehicle', function() SetTimeout(0, updatePrompt) end)
lib.onCache('seat', function() SetTimeout(0, updatePrompt) end)
AddEventHandler('cobalt_mechanic:closed', updatePrompt)

for id, shop in pairs(config.shops) do
    lib.zones.box({
        coords = shop.zone.coords,
        size = shop.zone.size,
        rotation = shop.zone.rotation,
        onEnter = function()
            currentShop = id
            updatePrompt()
        end,
        onExit = function()
            if currentShop == id then currentShop = nil end

            updatePrompt()
        end,
    })

    if shop.blip then
        local blip <const> = AddBlipForCoord(shop.zone.coords.x, shop.zone.coords.y, shop.zone.coords.z)

        SetBlipSprite(blip, shop.blip.sprite)
        SetBlipColour(blip, shop.blip.colour)
        SetBlipScale(blip, 0.8)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(locale('shop.' .. id))
        EndTextCommandSetBlipName(blip)
    end

    if shop.mode == 'employee' and shop.duty then
        exports.ox_target:addSphereZone({
            coords = shop.duty,
            radius = 1.2,
            options = {
                {
                    name = 'cobalt_mechanic:duty:' .. id,
                    label = locale('target.duty'),
                    icon = 'fas fa-id-badge',
                    canInteract = function() return management:GetJob()?.name == shop.job end,
                    onSelect = function() TriggerServerEvent('cobalt_core:ToggleDuty') end,
                },
                {
                    name = 'cobalt_mechanic:account:' .. id,
                    label = locale('target.account'),
                    icon = 'fas fa-building-columns',
                    canInteract = function()
                        local job <const> = management:GetJob()

                        return job?.name == shop.job and job.isboss == true
                    end,
                    onSelect = function() management:OpenMenu('job') end,
                },
            },
        })
    end
end

exports.ox_target:addGlobalVehicle({
    {
        name = 'cobalt_mechanic:customise',
        label = locale('target.work'),
        icon = 'fas fa-screwdriver-wrench',
        distance = 3.0,
        canInteract = function()
            local shop <const> = currentShop and config.shops[currentShop]

            if not shop or shop.mode ~= 'employee' or cache.vehicle or Menu.isOpen() then return false end

            return onDutyFor(shop.job)
        end,
        onSelect = function(data)
            Menu.open(currentShop --[[@as string]], data.entity)
        end,
    },
})

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource and promptShown then core:HideTextUI() end
end)
