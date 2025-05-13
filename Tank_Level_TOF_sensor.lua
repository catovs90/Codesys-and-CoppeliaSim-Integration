sim = require('sim')

-- === User Region ===
local sensorDigitalOutput = "DIx"       -- PLC Digital Output Signal
local sensorAnalogOutput = "AIW0"       -- PLC Analog Output Signal
local graphOutput = "graphLevel_1"      -- Used for local Graphing in CoppeliaSim
local tankHeight = 1.30                 -- Full tank height in meters (used when inverting)
local sensorOffset = 0.1                -- Offset from detection volume in volume properties (m)
local invertOutput = true               -- Set to true to invert (level style)
local debugMode = false                 -- Set to true for debugging info
-- === End User Region ===

local sensorHandle

function sysCall_init()
    sensorHandle = sim.getObjectParent(sim.getObject('.'))
    if debugMode then
        sim.addStatusbarMessage("[DEBUG] Laser Sensor initialized. Handle: " .. tostring(sensorHandle))
    end
end

function sysCall_sensing()
    local res, dist = sim.handleProximitySensor(sensorHandle)

    local digitalSignal = 0
    local analogSignal = -1

    if res > 0 then
        digitalSignal = 1
        local value = dist - sensorOffset

        if invertOutput then
            value = tankHeight - value
        end

        analogSignal = math.floor(value * 1000 * 10)  -- convert to 0,1 mm
        graphSignal = (analogSignal / 10)

        if debugMode then
            sim.addStatusbarMessage("[DEBUG] Raw distance: " .. string.format("%.3f", dist))
            sim.addStatusbarMessage("[DEBUG] Output value: " .. tostring(analogSignal / 10) .. " mm")
        end
    elseif debugMode then
        sim.addStatusbarMessage("[DEBUG] No detection.")
    end

    sim.setInt32Signal(sensorDigitalOutput, digitalSignal)
    sim.setInt32Signal(sensorAnalogOutput, analogSignal)
    if res > 0 then
        sim.setInt32Signal(graphOutput, graphSignal)
    else
        sim.setInt32Signal(graphOutput, -1)
    end
    
end

function sysCall_cleanup()
    sim.setInt32Signal(sensorDigitalOutput, 0)
    sim.setInt32Signal(sensorAnalogOutput, -1)

    if debugMode then
        sim.addStatusbarMessage("[DEBUG] Sensor signals reset during cleanup.")
    end
end
