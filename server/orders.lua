local config <const> = require 'config'
local Changes <const> = require 'shared.changes'
local Fitting <const> = require 'server.fitting'
local Sessions <const> = require 'server.sessions'
local Staff <const> = require 'server.staff'
local Vehicles <const> = require 'server.vehicles'

local core <const> = exports.cobalt_core
local banking <const> = exports.cobalt_banking
local inventory <const> = exports.cobalt_inventory

---@class MechanicOrder
---@field lines MechanicLine[]
---@field subtotal integer
---@field props table
---@field repairs ('engine'|'body')[]
---@field services MechanicWearSystem[]
---@field materials table<string, integer>

---@class MechanicBill
---@field id integer
---@field session MechanicSession
---@field customer integer
---@field order MechanicOrder
---@field markup integer percent
---@field prices integer[] charged per line, markup included
---@field total integer
---@field expiresAt integer epoch seconds

local Orders <const> = {}

---@type table<integer, MechanicBill>
local bills <const> = {}
local nextBillId = 0

---@param source integer
---@param message string
---@param kind? 'error'|'success'|'info'
local function notify(source, message, kind)
    core:Notify(source, { description = message, type = kind or 'error' })
end

---@param item string
---@return string
local function itemLabel(item)
    return inventory:GetItemDef(item)?.label or item
end

---@param session MechanicSession
---@param changes any
---@return MechanicOrder? order
---@return string? error
local function build(session, changes)
    local lines <const>, err <const> = Changes.resolveAll(changes, Changes.health(session.entity))

    if not lines then
        return nil, err
    end

    local order <const> = {
        lines = lines,
        subtotal = Changes.total(lines),
        props = Changes.props(lines),
        repairs = {},
        services = {},
        materials = session.shop.mode == 'employee' and Changes.materials(lines) or {},
    }

    for _, line in ipairs(lines) do
        if line.repair then order.repairs[#order.repairs + 1] = line.repair end
        if line.service then order.services[#order.services + 1] = line.service end
    end

    if session.shop.mode == 'employee' then
        local needed <const> = Changes.requiredGrade(lines)
        local grade <const> = Staff.grade(session.source, session.shop.job)

        if needed > grade then
            return nil, locale('errors.grade_needed', needed, grade)
        end
    end

    return order
end

---@param source integer
---@param materials table<string, integer>
---@return string? missing
local function missingMaterial(source, materials)
    for item, count in pairs(materials) do
        if inventory:GetItemCount(source, item) < count then
            return itemLabel(item)
        end
    end
end

---@param session MechanicSession
---@return boolean
local function readyToFit(session)
    return Sessions.isCurrent(session) and not Fitting.busy(session.source)
end

---@param session MechanicSession
---@param order MechanicOrder
local function fit(session, order)
    Vehicles.apply(session.entity, order.props, order.repairs, order.services)
    TriggerClientEvent('cobalt_mechanic:applied', session.source, order.props)
end

---@param session MechanicSession
---@param order MechanicOrder
---@param category string
---@param message string
---@param data table
local function log(session, order, category, message, data)
    data.shop = session.shopId
    data.plate = session.plate
    data.lines = order.lines

    core:LogPlayer(session.source, category, message, data)
end

---@param markup any
---@return integer percent
local function clampMarkup(markup)
    return math.max(0, math.min(config.billing.maxMarkup, math.floor(tonumber(markup) or 0)))
end

---@param lines MechanicLine[]
---@param markup integer percent
---@return integer[] prices
---@return integer total
local function markedUp(lines, markup)
    local prices <const>, total = {}, 0

    for i, line in ipairs(lines) do
        prices[i] = math.floor(line.price * (1 + markup / 100) + 0.5)
        total += prices[i]
    end

    return prices, total
end

---@param source integer
---@param changes any
---@param markup any
---@return table
function Orders.quote(source, changes, markup)
    local session <const> = Sessions.get(source)

    if not session then
        return { lines = {}, total = 0, materials = {}, crew = {}, error = locale('errors.away_from_car') }
    end

    local order <const>, err <const> = build(session, changes)

    if not order then
        return { lines = {}, total = 0, materials = {}, crew = {}, error = err }
    end

    local materials <const>, crew <const> = {}, {}

    for item, count in pairs(order.materials) do
        materials[#materials + 1] = {
            item = item,
            label = itemLabel(item),
            need = count,
            have = inventory:GetItemCount(source, item),
        }
    end

    if session.shop.mode == 'employee' then
        for _, member in ipairs(Staff.crew(session.shop.job, GetEntityCoords(session.entity))) do
            crew[#crew + 1] = Sessions.playerName(member)
        end
    end

    local lines <const> = {}

    for i, line in ipairs(order.lines) do lines[i] = { key = line.key, label = line.label, price = line.price } end

    local percent <const> = session.shop.mode == 'employee' and clampMarkup(markup) or 0

    local total <const> = select(2, markedUp(order.lines, percent))

    return { lines = lines, total = total, materials = materials, crew = crew }
end

---@param source integer
---@param changes any
---@param method any
---@return { ok: boolean, error?: string }
function Orders.checkout(source, changes, method)
    local session <const> = Sessions.get(source)

    if not session or session.shop.mode ~= 'self' then
        return { ok = false, error = locale('errors.away_from_car') }
    end

    if method ~= 'bank' and method ~= 'cash' then
        return { ok = false, error = locale('errors.pick_method') }
    end

    local order <const>, err <const> = build(session, changes)

    if not order then
        return { ok = false, error = err }
    end

    local description <const> = ('%s, %s'):format(session.shopLabel, session.plate)
    local society <const> = 'society_' .. session.shop.job
    local paid, payError = true, nil

    if order.subtotal > 0 and method == 'bank' then
        paid, payError = banking:Transfer(session.citizenid, society, order.subtotal, {
            note = description,
            initiator = session.citizenid,
            bill = true,
        })
    elseif order.subtotal > 0 then
        local player <const> = core:GetPlayer(source)
        local details <const> = { note = description, initiator = session.citizenid }

        paid = player ~= nil and player.Functions.RemoveMoney('cash', order.subtotal, description)

        if paid and not banking:Deposit(society, order.subtotal, details) then
            player.Functions.AddMoney('cash', order.subtotal, 'cobalt_mechanic:refund')
            paid = false
        end
    end

    if not paid then
        return { ok = false, error = payError or locale('errors.cannot_afford') }
    end

    fit(session, order)
    log(session, order, 'mechanic.checkout', ('Paid $%d at %s'):format(order.subtotal, session.shopLabel), {
        method = method,
        total = order.subtotal,
    })

    return { ok = true }
end

---@param bill MechanicBill
---@param status 'paid'|'declined'|'expired'|'failed'
---@param message? string
local function tellMechanic(bill, status, message)
    TriggerClientEvent('cobalt_mechanic:billStatus', bill.session.source, {
        status = status,
        customer = Sessions.playerName(bill.customer),
        message = message,
    })
end

---@param session MechanicSession
---@param order MechanicOrder
---@return { ok: boolean, error?: string }
local function billShop(session, order)
    if not Staff.canBillShop(session.source, session.shop.job) then
        return { ok = false, error = locale('errors.rank_shop_bill') }
    end

    local society <const> = 'society_' .. session.shop.job
    local description <const> = locale('bank.parts', session.plate)

    local withdrawn <const> = order.subtotal == 0
        or banking:Withdraw(society, order.subtotal, { note = description, initiator = session.citizenid })

    if not withdrawn then
        return { ok = false, error = locale('errors.shop_cannot_afford') }
    end

    if not readyToFit(session) then
        Fitting.deposit(session, society, order.subtotal, locale('bank.parts_refund'))

        return { ok = false, error = locale('errors.shop_not_started') }
    end

    local prices <const> = markedUp(order.lines, 0)
    local message <const> = ('Charged $%d to the %s account'):format(order.subtotal, session.shop.job)
    local payer <const> = { kind = 'shop', account = society, name = locale('fitting.shop_payer') }

    log(session, order, 'mechanic.shop_bill', message, { total = order.subtotal })
    Fitting.start(session, order.lines, prices, payer, order.subtotal)

    return { ok = true }
end

---@param bill MechanicBill
---@return table
local function billView(bill)
    local lines <const> = {}

    for i, line in ipairs(bill.order.lines) do
        lines[i] = { key = line.key, label = line.label, price = bill.prices[i] }
    end

    local customerCid <const> = Sessions.citizenid(bill.customer)

    return {
        id = bill.id,
        shop = bill.session.shopLabel,
        mechanic = Sessions.playerName(bill.session.source),
        plate = bill.session.plate,
        netId = bill.session.netId,
        lines = lines,
        total = bill.total,
        bankAfter = (customerCid and banking:GetBalance(customerCid) or 0) - bill.total,
        expiresInSeconds = math.max(0, bill.expiresAt - os.time()),
    }
end

---@param session MechanicSession
---@return MechanicBill?
local function pendingFor(session)
    for _, bill in pairs(bills) do
        if bill.session == session then
            return bill
        end
    end
end

---@param customer integer
---@return boolean
local function awaitingAnswer(customer)
    for _, bill in pairs(bills) do
        if bill.customer == customer then
            return true
        end
    end

    return false
end

---@param source integer
---@param data any
---@return { ok: boolean, error?: string }
function Orders.sendBill(source, data)
    local session <const> = Sessions.get(source)

    if type(data) ~= 'table' or not session or session.shop.mode ~= 'employee' then
        return { ok = false, error = locale('errors.away_from_car') }
    end

    if not Staff.onDutyJob(source, session.shop.job) then
        return { ok = false, error = locale('errors.off_duty') }
    end

    if Fitting.busy(source) then
        return { ok = false, error = locale('errors.still_fitting') }
    end

    if pendingFor(session) then
        return { ok = false, error = locale('errors.bill_pending') }
    end

    local order <const>, err <const> = build(session, data.changes)

    if not order then
        return { ok = false, error = err }
    end

    local missing <const> = missingMaterial(source, order.materials)

    if missing then
        return { ok = false, error = locale('errors.need_more', missing) }
    end

    if data.payer == 'shop' then
        return billShop(session, order)
    end

    local customer <const> = tonumber(data.target)
    local ped <const> = customer and GetPlayerPed(customer) or 0

    if ped == 0 or not Sessions.citizenid(customer --[[@as integer]]) then
        return { ok = false, error = locale('errors.pick_customer') }
    end

    if #(GetEntityCoords(ped) - GetEntityCoords(session.entity)) > config.billing.customerRadius then
        return { ok = false, error = locale('errors.customer_away') }
    end

    if awaitingAnswer(customer --[[@as integer]]) then
        return { ok = false, error = locale('errors.customer_busy') }
    end

    local markup <const> = clampMarkup(data.markup)
    local prices <const>, total <const> = markedUp(order.lines, markup)

    nextBillId += 1

    ---@type MechanicBill
    local bill <const> = {
        id = nextBillId,
        session = session,
        customer = customer --[[@as integer]],
        order = order,
        markup = markup,
        prices = prices,
        total = total,
        expiresAt = os.time() + config.billing.expireSeconds,
    }

    bills[bill.id] = bill
    TriggerClientEvent('cobalt_mechanic:bill', bill.customer, billView(bill))

    SetTimeout(config.billing.expireSeconds * 1000, function()
        if bills[bill.id] ~= bill then return end

        bills[bill.id] = nil
        tellMechanic(bill, 'expired')
        TriggerClientEvent('cobalt_mechanic:billCancelled', bill.customer, bill.id)
    end)

    return { ok = true }
end

---@param source integer
---@param id any
---@param accept any
---@return { ok: boolean, error?: string }
function Orders.answerBill(source, id, accept)
    local bill <const> = bills[tonumber(id) or -1]

    if not bill or bill.customer ~= source then
        return { ok = false, error = locale('errors.bill_expired') }
    end

    bills[bill.id] = nil

    if accept ~= true then
        tellMechanic(bill, 'declined')
        return { ok = true }
    end

    local session <const> = bill.session
    local customerCid <const> = Sessions.citizenid(source)

    if not customerCid or not Sessions.isCurrent(session) then
        tellMechanic(bill, 'failed', locale('status.mechanic_left'))
        return { ok = false, error = locale('errors.mechanic_left') }
    end

    if missingMaterial(session.source, bill.order.materials) then
        tellMechanic(bill, 'failed', locale('errors.parts_gone'))
        return { ok = false, error = locale('errors.mechanic_missing_parts') }
    end

    local description <const> = ('%s, %s'):format(session.shopLabel, session.plate)
    local paid, payError = true, nil

    if bill.total > 0 then
        paid, payError = banking:Withdraw(customerCid, bill.total, { note = description, initiator = session.citizenid })
    end

    if not paid then
        tellMechanic(bill, 'failed', locale('status.payment_failed'))
        return { ok = false, error = payError or locale('errors.bank_short') }
    end

    if not readyToFit(session) then
        Fitting.deposit(session, customerCid, bill.total, locale('bank.refund', description))
        tellMechanic(bill, 'failed', locale('status.not_started'))
        return { ok = false, error = locale('errors.not_started') }
    end

    tellMechanic(bill, 'paid')
    notify(source, locale('notify.paid', bill.total, session.shopLabel), 'success')
    log(session, bill.order, 'mechanic.bill_paid', ('Billed $%d for %s'):format(bill.total, session.plate), {
        customer = customerCid,
        markup = bill.markup,
        total = bill.total,
        subtotal = bill.order.subtotal,
    })

    local payer <const> = { kind = 'customer', account = customerCid, name = Sessions.playerName(source) }

    Fitting.start(session, bill.order.lines, bill.prices, payer, bill.total)

    return { ok = true }
end

---@param source integer
function Orders.cancelFor(source)
    for id, bill in pairs(bills) do
        if bill.session.source == source then
            bills[id] = nil
            TriggerClientEvent('cobalt_mechanic:billCancelled', bill.customer, id)
        elseif bill.customer == source then
            bills[id] = nil
            tellMechanic(bill, 'failed', locale('status.customer_left'))
        end
    end
end

AddEventHandler('playerDropped', function()
    Orders.cancelFor(source)
end)

return Orders
