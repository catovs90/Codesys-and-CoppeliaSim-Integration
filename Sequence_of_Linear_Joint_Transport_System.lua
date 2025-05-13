-- ==========================
-- USER REGION (Configurable)
-- ==========================

debugMode = false -- Enable or disable debug output

-- PLC Signals
dqSignal = "DQ0"                    -- PLC Digital Output
aqSignal = "AQW0"                   -- PLC Analog Output (Not implemented, planned for speed control)

-- Feedback Signals (Can be renamed to DIx for CODESYS)
joint_Ext = "joint_1_ext"           -- Fully extended position signal
joint_Ret = "joint_1_ret"           -- Fully retracted position signal

-- Interlock Conditions (Optional)
Interlock_Forward = "joint_0_ext"   -- Condition for forward motion
Interlock_Reverse = "joint_2_ext"   -- Condition for reverse motion

-- Motion Parameters
maxVelocity = 0.2                   -- Max movement speed (m/s) (If no AQ signal is used)
maxAcceleration = 0.5               -- Max acceleration (m/s?)
maxJerk = 2                         -- Max jerk (m/s?)
dampingFactor = 0.2                 -- Smooth stop factor
extendedThreshold = 0.01            -- Distance tolerance for extended position
retractedThreshold = 0.01           -- Distance tolerance for retracted position

-- ==========================
-- END OF USER REGION
-- ==========================

-- Runtime variables
local currentVelocity = 0
local currentAcceleration = 0
local dq0Signal = 0
local interlockFwd = 0
local interlockRev = 0
local jointHandle = nil
local jointPosition = 0
local minPosition = 0
local maxPosition = 0.5  -- Adjust this based on your setup

function sysCall_init()
    sim = require('sim')

    -- Get parent object (prismatic joint)
    local parentHandle = sim.getObjectParent(sim.getObject('.'))
    
    -- Validate if parent is a prismatic joint
    if parentHandle and sim.getJointType(parentHandle) == sim.joint_prismatic_subtype then
        jointHandle = parentHandle
        sim.setJointTargetVelocity(jointHandle, 0)  -- Start with zero speed

        -- Read min and max range from joint properties
        local isCyclic, interval = sim.getJointInterval(jointHandle)  -- Returns (boolean, {min, range})

        if interval then
            minPosition = interval[1]  -- Min position
            maxPosition = interval[1] + interval[2]  -- Min + range = Max position
        else
            sim.addLog(sim.verbosity_errors, "Error: Failed to retrieve joint interval!")
            minPosition, maxPosition = 0, 0  -- Default values
        end

        if debugMode then
            sim.addLog(sim.verbosity_scriptinfos, string.format("Min Pos: %.3f | Max Pos: %.3f", minPosition, maxPosition))
        end
    else
        sim.addLog(sim.verbosity_errors, "Error: Parent is not a prismatic joint!")
    end
end



function sysCall_sensing()
    if not jointHandle then return end  -- Exit if no valid joint is found

    -- Read signals
    dq0Signal = sim.getInt32Signal(dqSignal) or 0
    interlockFwd = sim.getInt32Signal(Interlock_Forward) or 0
    interlockRev = sim.getInt32Signal(Interlock_Reverse) or 0

    -- Get current joint position
    jointPosition = sim.getJointPosition(jointHandle)

    -- Determine movement direction
    local targetVelocity = 0

    -- Move forward if DQ signal is active AND interlock condition allows
    if dq0Signal == 1 and interlockFwd == 1 then
        targetVelocity = maxVelocity
    end

    -- Move backward if interlock reverse is active
    if interlockRev == 1 then
        targetVelocity = -maxVelocity
    end

    -- Apply damping when stopping
    if targetVelocity == 0 and math.abs(currentVelocity) < 0.05 then
        currentVelocity = currentVelocity * dampingFactor
    end

    -- Prevent small velocity fluctuations
    if math.abs(currentVelocity) < 0.01 then
        currentVelocity = 0
    end

    -- Apply acceleration limit
    local velocityChange = targetVelocity - currentVelocity
    local accelerationStep = math.min(math.abs(velocityChange) * maxJerk, maxAcceleration) * sim.getSimulationTimeStep()

    if velocityChange > 0 then
        currentAcceleration = math.min(currentAcceleration + accelerationStep, maxAcceleration)
    elseif velocityChange < 0 then
        currentAcceleration = math.max(currentAcceleration - accelerationStep, -maxAcceleration)
    else
        currentAcceleration = 0  -- No acceleration when velocity is stable
    end

    -- Update velocity
    currentVelocity = currentVelocity + currentAcceleration * sim.getSimulationTimeStep()
    currentVelocity = math.min(math.max(currentVelocity, -maxVelocity), maxVelocity)  -- Clamp velocity

    -- Set joint velocity
    sim.setJointTargetVelocity(jointHandle, currentVelocity)

    -- Set position feedback signals
    if math.abs(jointPosition - maxPosition) < extendedThreshold then
        sim.setInt32Signal(joint_Ext, 1)  -- Extended position reached
        sim.setInt32Signal(joint_Ret, 0)
    elseif math.abs(jointPosition - minPosition) < retractedThreshold then
        sim.setInt32Signal(joint_Ext, 0)
        sim.setInt32Signal(joint_Ret, 1)  -- Retracted position reached
    else
        sim.setInt32Signal(joint_Ext, 0)
        sim.setInt32Signal(joint_Ret, 0)  -- Moving
    end

    -- ==========================
    -- DEBUG MODE (Print Values)
    -- ==========================
    if debugMode then
        local debugMsg = string.format(
            "Joint Position: %.3f | Joint Ext: %d | Joint Ret: %d | Target Vel: %.2f | Current Vel: %.2f | DQ0: %d | Interlock Fwd: %d | Interlock Rev: %d",
            jointPosition, sim.getInt32Signal(joint_Ext), sim.getInt32Signal(joint_Ret),
            targetVelocity, currentVelocity, dq0Signal, interlockFwd, interlockRev
        )
        sim.addLog(sim.verbosity_scriptinfos, debugMsg)
    end
end
