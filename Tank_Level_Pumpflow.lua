sim = require('sim')
-- === USER SETTINGS ===
local pumpSpeedSignal = 'AQW0'          -- WORD from CODESYS (Pump speed)
local maxPumpflow = 6.43                -- Max Pumpflow i (m^3/h) 
local debugMode = false                 -- Set to true for debugging info
-- =======================

--=== Declaring and setting some initial variables ===   

function sysCall_actuation()
    local dt = sim.getSimulationTimeStep()
    
    --== Water Inflow calculations (m^3/s) === 
    local pumpflow_raw = sim.getInt32Signal(pumpSpeedSignal) or 0
    local pumpflow_percent = (pumpflow_raw / 65535 * 100)
    local pumpflow = (pumpflow_percent / 100) * (maxPumpflow / 3600)  
    sim.setFloatSignal('Tank1_pumpflow', pumpflow) 
        
    --===Debugging===
    if debugMode then
        sim.addStatusbarMessage("[DEBUG] Inflow: " .. string.format("%.3f", pumpflow*3600) .. " m3/h ("
        .. string.format("%.1f", pumpflow_percent) .. "%) (" .. string.format("%.1f", pumpflow*1000) .. "l/s)")
           
    end
end

