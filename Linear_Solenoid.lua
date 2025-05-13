sim = require('sim')

-- User Region
local plcSignal = 'DQ1'         -- PLC Output Signal for controlling the joint
local startPosition = 0.0       -- Starting position of the joint
local endPosition = 0.04        -- End position of the joint (meters)
local debugMode = false         -- Enable debugging output
-- End of User Region

-- Internal Variables
local jointHandle

function sysCall_init()
    -- Get the handle of the uniquely named joint   
    --jointHandle = sim.getObjectHandle('Prismatic_joint_unique_name')    
    jointHandle = sim.getObjectParent(sim.getObject('.'))
    
    if debugMode then
        sim.addStatusbarMessage(string.format("[DEBUG] Prismatic joint initialized. Handle: %d", jointHandle))
    end
end

function sysCall_actuation()
    -- Read the PLC signal
    local signalValue = sim.getInt32Signal(plcSignal)

    -- Decide target position based on signal
    local targetPosition = (signalValue == 1) and endPosition or startPosition

   -- Move the joint to the target position
    sim.setJointTargetPosition(jointHandle, targetPosition)

    -- Debugging output
    if debugMode then
        sim.addStatusbarMessage(string.format(
            "[DEBUG] Target position set to: %.4f | PLC Signal (%s): %d", targetPosition, plcSignal, signalValue))
    end

end

function sysCall_sensing()
    -- No sensing needed for this script
end

function sysCall_cleanup()
    -- Reset joint to start position when simulation stops
    sim.setJointTargetPosition(jointHandle, startPosition)

    if debugMode then
        sim.addStatusbarMessage(string.format(
            "[DEBUG] Joint reset to start position (%.4f) during cleanup. PLC Signal (%s): %d",
            startPosition, plcSignal, sim.getInt32Signal(plcSignal)))
    end
end
