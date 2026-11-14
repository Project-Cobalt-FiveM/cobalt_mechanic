---@alias MechanicCameraView 'front'|'side'|'rear'|'wheel'|'engine'|'interior'

---@class MechanicCameraFrame
---@field angle number degrees around the car, 0 in front
---@field pitch number degrees above the target
---@field distance number
---@field target vector3 offset from the car's origin

---@type table<MechanicCameraView, MechanicCameraFrame>
local VIEWS <const> = {
    front = { angle = 25, pitch = 10, distance = 6.0, target = vec3(0.0, 0.0, 0.3) },
    side = { angle = 90, pitch = 8, distance = 6.0, target = vec3(0.0, 0.0, 0.3) },
    rear = { angle = 180, pitch = 10, distance = 6.0, target = vec3(0.0, 0.0, 0.3) },
    wheel = { angle = 70, pitch = 4, distance = 2.6, target = vec3(-0.8, 1.2, -0.1) },
    engine = { angle = 0, pitch = 40, distance = 3.4, target = vec3(0.0, 1.6, 0.5) },
    interior = { angle = 160, pitch = 12, distance = 0.9, target = vec3(0.0, 0.4, 0.55) },
}

local MIN_DISTANCE <const>, MAX_DISTANCE <const> = 0.8, 10.0
local MIN_PITCH <const>, MAX_PITCH <const> = -10, 70

local Camera <const> = {}

---@param preset MechanicCameraFrame
---@return MechanicCameraFrame
local function copy(preset)
    return { angle = preset.angle, pitch = preset.pitch, distance = preset.distance, target = preset.target }
end

---@type integer?
local cam

---@type integer?
local vehicle

---@type MechanicCameraFrame
local frame = VIEWS.front

local function place()
    if not cam or not vehicle or not DoesEntityExist(vehicle) then return end

    local angle <const>, pitch <const> = math.rad(frame.angle), math.rad(frame.pitch)
    local reach <const> = frame.distance * math.cos(pitch)
    local around <const> = vec3(math.sin(angle) * reach, math.cos(angle) * reach, math.sin(pitch) * frame.distance)
    local offset <const> = frame.target + around
    local position <const> = GetOffsetFromEntityInWorldCoords(vehicle, offset.x, offset.y, offset.z)
    local target <const> = GetOffsetFromEntityInWorldCoords(vehicle, frame.target.x, frame.target.y, frame.target.z)

    SetCamCoord(cam, position.x, position.y, position.z)
    PointCamAtCoord(cam, target.x, target.y, target.z)
end

---@param entity integer
function Camera.start(entity)
    vehicle = entity
    frame = copy(VIEWS.front)
    cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 50.0, false, 2)

    place()
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 300, true, false)
end

function Camera.stop()
    if not cam then return end

    RenderScriptCams(false, true, 300, true, false)
    DestroyCam(cam, false)
    cam, vehicle = nil, nil
end

---@param view any
function Camera.view(view)
    local preset <const> = VIEWS[view]

    if not preset then return end

    frame = copy(preset)
    place()
end

---@param dx number
---@param dy number
function Camera.orbit(dx, dy)
    frame.angle = (frame.angle - dx * 0.3) % 360
    frame.pitch = math.max(MIN_PITCH, math.min(MAX_PITCH, frame.pitch + dy * 0.2))
    place()
end

---@param delta number
function Camera.zoom(delta)
    frame.distance = math.max(MIN_DISTANCE, math.min(MAX_DISTANCE, frame.distance + delta * 0.004))
    place()
end

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then Camera.stop() end
end)

return Camera
