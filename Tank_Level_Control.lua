sim = require('sim')

-- === USER SETTINGS ===
local outValveSignal = 'AQW1'       -- WORD from CODESYS (valve position)
--Tank parameters
local maxHeight = 1.3               -- Max tank height (m)
local tankRadius = 0.1              -- Tank radius(m)
local outletPipeArea = 0.000275        -- m^2 (max opening at 100%)
local debugMode = false             -- Set to true for debugging info
-- === END OF USER SETTINGS ===

--=== Declaring and setting some initial variables ===
local jointHandle
local volume = 0
local tankArea = math.pi * tankRadius^2
local g = 9.81

function sysCall_init()
    jointHandle = sim.getObjectParent(sim.getObject('.'))
end

function sysCall_actuation()
    local dt = sim.getSimulationTimeStep()
    
    --== Water Inflow from pump(m^3/s) === 
    local inflow = sim.getFloatSignal('Tank1_pumpflow') or 0
        
    --=== Outflow valve position (%) ===
    local valveSignal_raw = sim.getInt32Signal(outValveSignal) or 0
    local valvePercent = (valveSignal_raw / 65535 * 100)
    if valvePercent < 0 then valvePercent = 0 end
    if valvePercent > 100 then valvePercent = 100 end
    
    --=== Water Outflow calculations (m^3/s ===
    local height = sim.getJointPosition(jointHandle)
    local valveOpening = (valvePercent / 100.0) * outletPipeArea
    local outflow = valveOpening * math.sqrt(2 * g * height)
    
    --=== Tank level Calculations (m) ===
    volume = volume + (inflow - outflow) * dt
    if volume < 0 then volume = 0 end
    local newHeight = volume / tankArea
    if newHeight > maxHeight then
        newHeight = maxHeight
        volume = tankArea * maxHeight
    end
    
    --=== Setting new level (m) ===
    sim.setJointTargetPosition(jointHandle, newHeight)
    sim.setFloatSignal('Tank1_Outflow', outflow)
    sim.setFloatSignal('Tank1_Water_Level', newHeight)
    
    --===Debugging===
    if debugMode then
        sim.addStatusbarMessage("[DEBUG] Inflow: " .. string.format("%.3f", inflow*3600) .. " m3/h (" .. string.format("%.1f", inflow*1000) .. "l/s)")
        sim.addStatusbarMessage("[DEBUG] Outflow: " .. string.format("%.3f", outflow*3600) .. " m3/h (" .. string.format("%.1f", valvePercent) .. "%) (" .. string.format("%.1f", outflow*1000) .. "l/s)")
        sim.addStatusbarMessage("[DEBUG] Level: " .. string.format("%.3f", newHeight * 1000) .. " mm")        
    end
end


