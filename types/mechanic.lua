---@meta

---@alias MechanicShopMode 'employee'|'self'
---@alias MechanicWearSystem 'brakes'|'clutch'|'oil'|'battery'|'tyres'

---@class MechanicShop
---@field job string the cobalt_core job whose society account takes the money and whose staff run the shop
---@field mode MechanicShopMode `employee`: on-duty staff customise and bill the customer. `self`: owners customise their own car and pay at checkout
---@field zone { coords: vector3, size: vector3, rotation: number }
---@field duty? vector3 staff point for duty and the shop account, employee shops only
---@field blip? { sprite: integer, colour: integer }

---@class MechanicStats
---@field topSpeed integer km/h
---@field acceleration number 0 to 10 against the class best
---@field braking number 0 to 10 against the class best
---@field handling number 0 to 10 against the class best
---@field traction number 0 to 10 against the class best
---@field armour integer percent
