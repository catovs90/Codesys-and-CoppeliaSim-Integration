simUI = require("simUI")                    -- Ensure simUI is enabled

-- ======= USER REGION =======
local signalName = "DQx"                    -- Trigger signal from PLC
local spawnMode = "static"                  -- "static" or "dynamic"
local allowMultipleSpawns = false           -- true = spawn while signal is high, false = spawn only on rising edge
local respondableSpawn = true               -- true = object responds to collisions, false = object is purely visual
local despawnHeight = 0.05                  -- Height threshold for despawning fallen products

local xOffset = 0                           -- X offset from spawner
local yOffset = 0                           -- Y offset from spawner
local zOffset = 0.0                         -- Z offset from spawner

local DEBUG_MODE = false                    -- Print debug messages

-- ======= END OF USER REGION =======


local uiHandle = nil                        -- UI handle to manage the UI window
local initialPosition = nil                 -- Variable to store the initial position
local previousSignalValue = 0               -- Variable to store the last signal state (Spawn on Rising edge only)
local parentName = "Model"                  -- Default name if alias is missing
local spawnedProducts = {}                  -- Table to track spawned objects

-- Function to spawn the model
function SpawnModel()

    -- Get the handle for this script (Location of script is used for spawning location)
    local attachedObject = sim.getObject('.')
    -- Get the parent of the attached object (Parent is used to copy all objects in the model)
    local parentHandle = sim.getObject('..')
    
    if parentHandle == -1 then
        print("Error: No parent object found.")
        return
    end

    -- Get all objects in the parent's hierarchy (parent + children)
    local allObjects = sim.getObjectsInTree(parentHandle)

    -- Filter out script objects (avoid infinite spawning)
    local objectsToCopy = {}
        for i = 1, #allObjects do
            if sim.getObjectType(allObjects[i]) ~= sim.object_script_type then
                table.insert(objectsToCopy, allObjects[i])
            end
        end

    -- Copy only the filtered objects (no scripts included)
    local copiedObjects = sim.copyPasteObjects(objectsToCopy, 0)
    local copiedRootHandle = copiedObjects[1]

    -- Detach from parent and reset orientation
    sim.setObjectParent(copiedRootHandle, -1, true)
    sim.setObjectOrientation(copiedRootHandle, -1, {0, 0, 0})

    -- Determine spawn position
    local spawnPosition = {}
        if spawnMode == "dynamic" then
            initialPosition = sim.getObjectPosition(attachedObject, -1)
            if DEBUG_MODE then
                print("[Dynamic] Position stored at spawn time:", initialPosition[1], initialPosition[2], initialPosition[3])
            end
        end        

    spawnPosition = {
        initialPosition[1] + xOffset,
        initialPosition[2] + yOffset,
        initialPosition[3] + zOffset + 0.01 -- Small extra offset to avoid collision issues
    }

    sim.setObjectPosition(copiedRootHandle, -1, spawnPosition)

    -- Ensure the object is dynamic and respondable
    if respondableSpawn then
        sim.setObjectInt32Param(copiedRootHandle, sim.shapeintparam_respondable, 1)
    else
        sim.setObjectInt32Param(copiedRootHandle, sim.shapeintparam_respondable, 0)
    end
    sim.setObjectInt32Param(copiedRootHandle, sim.shapeintparam_static, 0)

    -- Reset dynamics to avoid unwanted forces
    sim.resetDynamicObject(copiedRootHandle)
    
    if DEBUG_MODE then
        print(parentName .. " hierarchy copied and spawned at:", spawnPosition[1], spawnPosition[2], spawnPosition[3])
    end    

    -- Register the spawned object for despawn tracking
    table.insert(spawnedProducts, copiedRootHandle)
end

-- Function to despawn objects that fall below a certain height
function despawnFallenProducts()
    for i = #spawnedProducts, 1, -1 do
        local obj = spawnedProducts[i]
            if sim.isHandleValid(obj) == 1 then
                local pos = sim.getObjectPosition(obj, -1)
                if pos[3] < despawnHeight then                        
                    sim.removeModel(obj)
                    table.remove(spawnedProducts, i)
                end
            else
                -- Remove invalid handles from the table (if already removed)
                table.remove(spawnedProducts, i)
            end
    end
end

-- Callback function for the UI button
function onSpawnButtonClick(ui, id)
    SpawnModel()
end

-- Function to create the UI window
function createUI()
    local xml = string.format([[<ui title="Spawner" closeable="true" on-close="onClose">
        <button text="Spawn %s" on-click="onSpawnButtonClick" />
    </ui>]], parentName)
    uiHandle = simUI.create(xml)
end

function sysCall_init()
    sim = require('sim')
    
    -- Get the handle for this script (Location of script is used for spawning location)
    local attachedObject = sim.getObject('.')
    
    -- Store initial position if static mode is selected
    if spawnMode == "static" then
        initialPosition = sim.getObjectPosition(attachedObject, -1)
        print("[Static] Initial position stored:", initialPosition[1], initialPosition[2], initialPosition[3])
    end

    -- Get the parent Handle and name (use alias if available)
    local parentHandle = sim.getObject('..')    
        if parentHandle ~= -1 then
            parentName = sim.getObjectAlias(parentHandle, 0)
            if parentName == nil or parentName == "" then
                parentName = sim.getObjectName(parentHandle) or "Model"
            end
        
            print("Detected parent object:", parentName)
        end
    
    createUI()
end

function sysCall_sensing()
    -- Read CODESYS signal (DQ[X])
    local signalValue = sim.getInt32Signal(signalName)

    -- Spawn product one time or multiple times (set in user region)
    if allowMultipleSpawns then
        if signalValue == 1 then
            SpawnModel()
        end
    else
        if signalValue == 1 and previousSignalValue == 0 then
            SpawnModel()
        end
    end

    -- Check for fallen objects and despawn them
    despawnFallenProducts()

    -- Store current signal value for next cycle
    previousSignalValue = signalValue
end

function sysCall_cleanup()
    simUI.destroy(uiHandle) -- Function to close the UI
end

