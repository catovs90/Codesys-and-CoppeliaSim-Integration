sim = require('sim')

--======== User Region ========
-- PLC Signals:
local startSignalName = "DQ0"           -- PLC signal for start/stop
local directionSignalName = "DQx"       -- PLC signal for reverse direction (optional)
local velocitySignalName = "AQW0"       -- PLC analog signal (0-65535 (mm/s))

-- Local Control:
local defaultVelocity = 0.3             -- Default conveyor velocity (m/s)
local defaultDirection = 1              -- Default direction: 1 for forward, -1 for reverse

local usePLCVelocity = true             -- true = use PLC analog word as speed
local usePLCDirection = false           -- true = use PLC digital for direction
local useSignedWordForVelocity = true   -- true = use signed word for +/- speed (positive: 0->32767, negative: 65535->32767) 
local debugMode = false                 -- Set to 'true' to enable debug prints
--======== End of User Region ========

local conveyorHandle

function sysCall_init()
    -- Automatically get the parent object (conveyor)
    conveyorHandle = sim.getObjectParent(sim.getObject('.'))
    if conveyorHandle == -1 then
        if debugMode then print("[WARNING] Conveyor handle not found. Make sure the script is a child of the conveyor") end
        return
    end
end

function sysCall_actuation()
    local plcSignal = sim.getInt32Signal(startSignalName)
    local velocity = defaultVelocity
    local direction = defaultDirection

    if usePLCVelocity then
        local plcVelocityRaw = sim.getInt32Signal(velocitySignalName)
        if plcVelocityRaw then
            if useSignedWordForVelocity then
                -- Convert unsigned word to signed 16-bit value
                if plcVelocityRaw >= 32768 then
                    plcVelocityRaw = plcVelocityRaw - 65536
                end
                velocity = plcVelocityRaw / 1000  -- Interpret directly as signed mm/s
            else
                velocity = plcVelocityRaw / 1000  -- Default positive mm/s only
            end
        end
    end

    if usePLCDirection and not useSignedWordForVelocity then
        local plcDirectionSignal = sim.getInt32Signal(directionSignalName)
        direction = (plcDirectionSignal == 1) and -1 or 1
    end

    -- Apply direction unless direction is embedded in signed word
    if not useSignedWordForVelocity then
        velocity = velocity * direction
    end

    if debugMode then
        print(string.format("[DEBUG] Start: %d | Dir: %d | Vel: %.3f m/s", plcSignal or -1, direction, velocity))
    end

    if plcSignal == 1 then
        sim.setBufferProperty(conveyorHandle, 'customData.__ctrl__', sim.packTable({vel = velocity}))
    else
        sim.setBufferProperty(conveyorHandle, 'customData.__ctrl__', sim.packTable({vel = 0.0}))
    end
end

function sysCall_cleanup()
    sim.setBufferProperty(conveyorHandle, 'customData.__ctrl__', sim.packTable({vel = 0.0}))
end
