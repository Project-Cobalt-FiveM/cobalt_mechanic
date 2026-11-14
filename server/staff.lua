local config <const> = require 'config'

local inventory <const> = exports.cobalt_inventory
local management <const> = exports.cobalt_management

local Staff <const> = {}

---@param source integer
---@param job string
---@return ManagementJob?
function Staff.onDutyJob(source, job)
    local current <const> = management:GetJob(source)

    if not current or current.name ~= job or not current.onduty then return end

    return current
end

---@param source integer
---@param job string
---@return integer
function Staff.grade(source, job)
    return Staff.onDutyJob(source, job)?.grade.level or 0
end

---@param source integer
---@param job string
---@return boolean
function Staff.canBillShop(source, job)
    return management:HasPermission(source, job, 'society') == true
end

---@param job string
---@param coords vector3
---@return integer[]
function Staff.crew(job, coords)
    local crew <const> = {}
    local radius <const> = config.billing.crewRadius

    for _, member in ipairs(management:GetOnlineMembers(job) or {}) do
        local ped <const> = GetPlayerPed(member)

        if ped ~= 0 and Staff.onDutyJob(member, job) and #(GetEntityCoords(ped) - coords) <= radius then
            crew[#crew + 1] = member
        end
    end

    return crew
end

---Takes the materials from the mechanic, all or none.
---@param source integer
---@param materials table<string, integer>
---@return boolean
function Staff.takeMaterials(source, materials)
    local taken <const> = {}

    for item, count in pairs(materials) do
        if not inventory:RemoveItem(source, item, count, nil, 'cobalt_mechanic:fit', true) then
            for done, amount in pairs(taken) do
                inventory:AddItem(source, done, amount, nil, nil, 'cobalt_mechanic:refund', true)
            end

            return false
        end

        taken[item] = count
    end

    return true
end

return Staff
