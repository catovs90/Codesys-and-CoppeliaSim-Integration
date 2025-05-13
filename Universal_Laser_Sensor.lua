sim = require('sim')

-- User Region.
local sensorDigitalOutput = "DI1"    -- PLC Digital Output Signal
local sensorAnalogOutput = "AIWx"    -- PLC Analog Output Signal (mm)
local sensorOffset = 0               -- Offset from detection volume properties
local debugMode = false              -- Set to true for debugging info
-- End of User Region.

local sensorHandle

function sysCall_init()
    -- Automatically get the parent object (sensor)
    sensorHandle = sim.getObjectParent(sim.getObject('.'))

    if debugMode then
        sim.addStatusbarMessage("[DEBUG] Laser Sensor initialized. Handle: " .. tostring(sensorHandle))
    end
end

function sysCall_sensing()
    -- Detect object and distance
    local res, dist = sim.handleProximitySensor(sensorHandle)

    -- Default signal states
    local digitalSignal = 0
    local analogSignal = -1

    -- Handle detection logic
    if res > 0 then
        digitalSignal = 1
        analogSignal = math.floor((dist - sensorOffset) * 1000)

        if debugMode then
            sim.addStatusbarMessage("[DEBUG] Detected object at distance: " .. tostring(dist))
        end
    elseif debugMode then
        sim.addStatusbarMessage("[DEBUG] No detection.")
    end

    -- Write signals to the PLC
    sim.setInt32Signal(sensorDigitalOutput, digitalSignal)
    sim.setInt32Signal(sensorAnalogOutput, analogSignal)
end

function sysCall_cleanup()
    -- Reset PLC signals on simulation stop
    sim.setInt32Signal(sensorDigitalOutput, 0)
    sim.setInt32Signal(sensorAnalogOutput, -1)

    if debugMode then
        sim.addStatusbarMessage("[DEBUG] Sensor signals reset during cleanup.")
    end
end

	

