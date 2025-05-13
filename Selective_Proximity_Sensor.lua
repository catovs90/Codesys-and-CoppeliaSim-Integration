sim = require('sim')

-- User Region.
local sensorDigitalOutput = "DI0"       -- PLC Digital Output Signal
local sensorAnalogOutput = "AIWx"       -- PLC Analog Output Signal (mm)
local sensorOffset = 0                  -- Offset from detection volume set in volume parameters
local detectionPatterns = {"ICT3_Peg"}  -- Object name patterns to detect ( {"obj1", "obj2"} )
local debugMode = false                 -- Enable for debugging info
-- End of User Region.

local sensorHandle

function sysCall_init()
    -- Automatically get the parent object (sensor)
    sensorHandle = sim.getObjectParent(sim.getObject('.'))

    if debugMode then
        sim.addStatusbarMessage("[DEBUG] Sensor initialized: " .. tostring(sensorHandle))
        sim.addStatusbarMessage("[DEBUG] Sensor initialized with detection patterns: " .. table.concat(detectionPatterns, ", "))
    end
end

function sysCall_sensing()
    -- Read sensor data
    local res, dist, _, detectedObjectHandle = sim.handleProximitySensor(sensorHandle)

    -- Default signal states
    local digitalSignal = 0
    local analogSignal = -1

    if res > 0 and detectedObjectHandle ~= -1 then
        -- Check if the object name matches any allowed pattern
        local objectName = sim.getObjectAlias(detectedObjectHandle, 0)
        local detected = false

        for _, pattern in ipairs(detectionPatterns) do
            if string.find(objectName, pattern) then
                detected = true
                break
            end
        end

        -- Update signals based on detection result
        if detected then
            digitalSignal = 1
            analogSignal = math.floor((dist - sensorOffset) * 1000)

            if debugMode then
                sim.addStatusbarMessage("[DEBUG] Detected object: " .. objectName .. " at distance: " .. tostring(dist))
            end
        elseif debugMode then
            sim.addStatusbarMessage("[DEBUG] Ignored object: " .. objectName)
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
end
