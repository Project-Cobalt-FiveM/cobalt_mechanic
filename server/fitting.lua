local config <const> = require 'config'
local Sessions <const> = require 'server.sessions'
local Staff <const> = require 'server.staff'
local Vehicles <const> = require 'server.vehicles'

local core <const> = exports.cobalt_core
local banking <const> = exports.cobalt_banking
local management <const> = exports.cobalt_management

local GRACE_MS <const> = 1500

---@alias MechanicFitStatus 'next'|'active'|'done'|'skipped'

---@class MechanicFitStep
---@field line MechanicLine
---@field price integer what the payer was charged for this line
---@field seconds integer
---@field status MechanicFitStatus

---@class MechanicPayer
---@field kind 'customer'|'shop'
---@field account string the bank account the job's money came out of, which refunds go back to
---@field name string

---@class MechanicFitJob
---@field id integer
---@field session MechanicSession
---@field payer MechanicPayer
---@field society string the shop's account, paid for each part fitted on a customer job
---@field total integer
---@field steps MechanicFitStep[]
---@field index integer
---@field startedAt integer game timer when the active step began
---@field coords vector3 where the car was last seen

local Fitting <const> = {}

---@type table<integer, MechanicFitJob>
local jobs <const> = {}
local nextJobId = 0

---@param line MechanicLine
---@return integer
local function secondsFor(line)
    local kind <const> = line.key:match('^[^:]+')

    return config.fitting[kind] or config.fitting.default
end

---@param job MechanicFitJob
---@return vector3
local function carCoords(job)
    if DoesEntityExist(job.session.entity) then
        job.coords = GetEntityCoords(job.session.entity)
    end

    return job.coords
end

---@param job MechanicFitJob
---@return table[]
local function crewView(job)
    local session <const> = job.session
    local coords <const> = carCoords(job)
    local crew <const> = {}

    for _, member in ipairs(Staff.crew(session.shop.job, coords)) do
        local grade <const> = management:GetJob(member)?.grade

        crew[#crew + 1] = {
            name = Sessions.playerName(member),
            role = grade?.name or locale('fitting.role'),
            grade = grade?.level or 0,
            distance = math.floor(#(GetEntityCoords(GetPlayerPed(member)) - coords)),
            isYou = member == session.source,
        }
    end

    return crew
end

---@param job MechanicFitJob
local function send(job)
    local items <const> = {}

    for i, step in ipairs(job.steps) do
        items[i] = {
            key = step.line.key,
            label = step.line.label,
            seconds = step.seconds,
            status = step.status,
        }
    end

    TriggerClientEvent('cobalt_mechanic:fitting', job.session.source, {
        id = job.id,
        paidBy = job.payer.name,
        total = job.total,
        index = job.index,
        sharesMarkup = job.payer.kind == 'customer',
        crewRadius = config.billing.crewRadius,
        items = items,
        crew = job.session.shop.mode == 'employee' and crewView(job) or {},
    })
end

---Deposits job money into an account and logs a security event when the bank refuses it.
---@param session MechanicSession
---@param account string
---@param amount integer
---@param note string
function Fitting.deposit(session, account, amount, note)
    if amount <= 0 then return end

    local ok <const> = banking:Deposit(account, amount, { note = note, initiator = session.citizenid })

    if ok then return end

    local message <const> = ('Could not pay $%d into %s for the job on %s'):format(amount, account, session.plate)

    core:LogPlayer(session.source, 'mechanic.deposit_failed', message, {
        account = account,
        owed = amount,
        mechanic = session.citizenid,
        shop = session.shopId,
    }, 'security')
end

---@param job MechanicFitJob
---@param step MechanicFitStep
---@param completed any
---@return boolean fitted
local function fits(job, step, completed)
    if completed ~= true then return false end
    if GetGameTimer() - job.startedAt < step.seconds * 1000 - GRACE_MS then return false end

    local source <const> = job.session.source

    if Staff.takeMaterials(source, step.line.materials or {}) then return true end

    core:Notify(source, { description = locale('notify.parts_missing', step.line.label), type = 'error' })

    return false
end

---@param job MechanicFitJob
---@param step MechanicFitStep
local function apply(job, step)
    local session <const> = job.session
    local line <const> = step.line

    Vehicles.apply(session.entity, line.props or {}, { line.repair }, { line.service })
    TriggerClientEvent('cobalt_mechanic:applied', session.source, line.props or {})

    if job.payer.kind == 'customer' then
        Fitting.deposit(session, job.society, step.price, locale('bank.fitted', line.label, session.plate))
    end
end

---@param job MechanicFitJob
local function payCrew(job)
    if job.payer.kind ~= 'customer' then return end

    local session <const> = job.session
    local markup = 0

    for _, step in ipairs(job.steps) do
        if step.status == 'done' then markup += step.price - step.line.price end
    end

    local share <const> = math.floor(markup * config.billing.mechanicShare)
    local crew = Staff.crew(session.shop.job, carCoords(job))

    if #crew == 0 then crew = { session.source } end

    local each <const> = math.floor(share / #crew)

    if each <= 0 then return end

    local details <const> = { note = locale('bank.crew_share', session.plate), initiator = job.payer.account }

    for _, member in ipairs(crew) do
        local citizenid <const> = Sessions.citizenid(member)

        if citizenid then banking:Transfer(job.society, citizenid, each, details) end
    end
end

---Logs the job and closes the fitting panel, without yielding.
---@param job MechanicFitJob
local function report(job)
    local fitted <const>, refunded = {}, 0

    for _, step in ipairs(job.steps) do
        if step.status == 'done' then
            fitted[#fitted + 1] = step.line.label
        else
            refunded += step.price
        end
    end

    local message <const> = ('Fitted %d parts on %s'):format(#fitted, job.session.plate)

    core:LogPlayer(job.session.source, 'mechanic.fitted', message, {
        shop = job.session.shopId,
        payer = job.payer.account,
        total = job.total,
        refunded = refunded,
        fitted = fitted,
    })

    TriggerClientEvent('cobalt_mechanic:fitting', job.session.source, nil)
end

---@param job MechanicFitJob
local function advance(job)
    local step <const> = job.steps[job.index]

    if step then
        step.status = 'active'
        job.startedAt = GetGameTimer()
        send(job)
        return
    end

    jobs[job.session.source] = nil
    report(job)
    payCrew(job)
end

---Starts fitting a paid order. The job holds the payer's money. Each part fitted on a customer job pays the
---shop, and each part not fitted goes back to the payer.
---@param session MechanicSession
---@param lines MechanicLine[]
---@param prices integer[] charged per line
---@param payer MechanicPayer
---@param total integer
function Fitting.start(session, lines, prices, payer, total)
    nextJobId += 1

    local steps <const> = {}

    for i, line in ipairs(lines) do
        steps[i] = { line = line, price = prices[i], seconds = secondsFor(line), status = 'next' }
    end

    ---@type MechanicFitJob
    local job <const> = {
        id = nextJobId,
        session = session,
        payer = payer,
        society = 'society_' .. session.shop.job,
        total = total,
        steps = steps,
        index = 1,
        startedAt = 0,
        coords = GetEntityCoords(session.entity),
    }

    jobs[session.source] = job
    advance(job)
end

---@param source integer
---@return boolean
function Fitting.busy(source)
    return jobs[source] ~= nil
end

---Ends the job early and pays every part not yet fitted back to the payer in one deposit.
---@param source integer
function Fitting.abort(source)
    local job <const> = jobs[source]

    if not job then return end

    jobs[source] = nil

    local owed = 0

    for _, step in ipairs(job.steps) do
        if step.status == 'next' or step.status == 'active' then
            step.status = 'skipped'
            owed += step.price
        end
    end

    report(job)
    Fitting.deposit(job.session, job.payer.account, owed, locale('bank.refund_unfitted', job.session.plate))
    payCrew(job)
end

---@param source integer
---@param id any
---@param index any
---@param completed any
---@return boolean
function Fitting.step(source, id, index, completed)
    local job <const> = jobs[source]

    if not job or job.id ~= id or job.index ~= index then return false end

    local step <const> = job.steps[index]

    if step.status ~= 'active' then return false end

    if not Sessions.isCurrent(job.session) then
        Fitting.abort(source)
        return false
    end

    step.status = 'skipped'
    job.index += 1

    if fits(job, step, completed) then
        step.status = 'done'
        apply(job, step)
    else
        Fitting.deposit(job.session, job.payer.account, step.price, locale('bank.refund', step.line.label))
    end

    if jobs[source] == job then advance(job) end

    return true
end

AddEventHandler('playerDropped', function()
    Fitting.abort(source)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    for source in pairs(jobs) do
        Citizen.CreateThreadNow(function() Fitting.abort(source) end)
    end
end)

return Fitting
