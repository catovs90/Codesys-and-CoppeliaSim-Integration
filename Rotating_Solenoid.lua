sim = require('sim')

-- User Region.
local plcSignal = "DQ2"            -- PLC Output Signal for controlling the joint
local startPosition = math.rad(-10) -- Start position in (degrees)
local endPosition = math.rad(30)    -- End position in (degrees)
local debugMode = false              -- Set to true for debugging info
-- End of User Region.

local jointHandle

function sysCall_init()
    -- Automatically get the parent joint object
    jointHandle = sim.getObjectParent(sim.getObject('.'))

    if debugMode then
        sim.addStatusbarMessage("[DEBUG] Revolute joint initialized. Handle: " .. tostring(jointHandle))
    end
end

function sysCall_actuation()
    -- Read the PLC signal safely
    local signalValue = sim.getInt32Signal(plcSignal) or 0

    -- Determine target position based on PLC signal
    local targetPosition = (signalValue == 1) and endPosition or startPosition

    -- Move the joint to the target position
    local result = sim.setJointTargetPosition(jointHandle, targetPosition)

    -- Debugging output
    if debugMode then
        local posString = (type(targetPosition) == "number") and string.format("%.4f", targetPosition) or "N/A"
        sim.addStatusbarMessage(string.format("[DEBUG] Joint moved to position: %s rad | PLC Signal (%s): %d", posString, plcSignal, signalValue))
    end
end

function sysCall_cleanup()
    -- Reset joint to start position on simulation stop
    sim.setJointTargetPosition(jointHandle, startPosition)

    if debugMode then
        local posString = (type(startPosition) == "number") and string.format("%.4f", startPosition) or "N/A"
        local signalValue = sim.getInt32Signal(plcSignal) or 0
        sim.addStatusbarMessage(string.format("[DEBUG] Joint reset to start position (%s rad) during cleanup. PLC Signal (%s): %d", posString, plcSignal, signalValue))
    end
end
