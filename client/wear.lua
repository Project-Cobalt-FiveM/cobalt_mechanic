local config <const> = require 'config'

---@type integer?
local interval

---@type integer?
local driving

local meters = 0
local lastPosition

local function report()
    if driving and meters > 1 and DoesEntityExist(driving) and NetworkGetEntityIsNetworked(driving) then
        TriggerServerEvent('cobalt_mechanic:drove', VehToNet(driving), meters)
    end

    meters = 0
end

local function sample()
    if not driving or not DoesEntityExist(driving) then return end

    local position <const> = GetEntityCoords(driving)

    if lastPosition then meters += #(position - lastPosition) end

    lastPosition = position
end

local function stop()
    if interval then ClearInterval(interval) end

    report()
    interval, driving, lastPosition = nil, nil, nil
end

local function update()
    local vehicle <const> = cache.seat == -1 and cache.vehicle or nil

    if vehicle == driving then return end

    stop()

    if not vehicle then return end

    driving = vehicle

    local samples = 0

    interval = SetInterval(function()
        sample()
        samples += 1

        if samples >= config.wear.reportSeconds then
            samples = 0
            report()
        end
    end, 1000)
end

lib.onCache('vehicle', function() SetTimeout(0, update) end)
lib.onCache('seat', function() SetTimeout(0, update) end)

update()
