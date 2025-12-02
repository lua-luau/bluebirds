-- DEBUG VERSION: Highlight ESP with FULL LOGGING
-- Run this, paste the ENTIRE console output here (F9 or executor console)
-- It will print EVERYTHING in Characters folder + checks each Model
-- Also forces highlights on ALL valid Models (even weapons for test)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local CharactersFolder = Workspace:WaitForChild("Characters")
local highlights = {}
local debug = true

local function log(msg)
    if debug then
        print("[ESP DEBUG] " .. tostring(msg))
    end
end

local function isPotentialPlayer(model)
    -- Super lenient: Any Model in Characters with Humanoid OR Capsule ANYWHERE
    local hasHumanoid = model:FindFirstChild("Humanoid", true)
    local hasCapsule = model:FindFirstChild("Capsule", true)
    local isModel = model.Name == "Model"
    local notCharacterC = model.Name ~= "Character_C"
    
    local valid = (hasHumanoid or hasCapsule) and isModel and notCharacterC and model.Parent == CharactersFolder
    log("Checking '" .. model.Name .. "': Humanoid=" .. tostring(hasHumanoid) .. ", Capsule=" .. tostring(hasCapsule) .. ", Valid=" .. tostring(valid))
    return valid
end

local function addHighlight(character)
    if highlights[character] or not character then return end
    
    -- DOUBLE SKIP OWN CHAR
    if character == LocalPlayer.Character then 
        log("Skipped own character")
        return 
    end
    
    -- Find root for PrimaryPart (helps highlighting)
    local capsule = character:FindFirstChild("Capsule", true)
    if capsule then
        character.PrimaryPart = capsule
    end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.Adornee = character
    highlight.FillColor = Color3.fromRGB(0, 255, 0)  -- GREEN for debug (easy to see)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.3
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = true
    
    -- PARENT TO WORKSPACE (fixes many visibility issues)
    highlight.Parent = Workspace
    
    highlights[character] = highlight
    log("ADDED HIGHLIGHT #" .. tostring(#(function() local t={} for _ in pairs(highlights) do table.insert(t,1) end return t end)()) .. " to '" .. character.Name .. "'")
end

local function removeHighlight(character)
    if highlights[character] then
        highlights[character]:Destroy()
        highlights[character] = nil
        log("Removed highlight for '" .. character.Name .. "'")
    end
end

-- FULL DEBUG SCAN
log("=== SCANNING CHARACTERS FOLDER ===")
log("Total children: " .. #CharactersFolder:GetChildren())
for i, child in ipairs(CharactersFolder:GetChildren()) do
    log("Child " .. i .. ": '" .. child.Name .. "' (Type: " .. child.ClassName .. ")")
    if child:IsA("Model") then
        log("  Subchildren count: " .. #child:GetChildren())
        for _, sub in ipairs(child:GetChildren()) do
            log("    - " .. sub.Name .. " (" .. sub.ClassName .. ")")
        end
        if isPotentialPlayer(child) then
            task.spawn(function()
                task.wait(0.5)  -- Extra wait for full load
                addHighlight(child)
            end)
        end
    end
end
log("Initial scan complete. Total highlights: " .. #(function() local t={} for _ in pairs(highlights) do table.insert(t,1) end return t end)())

-- LIVE UPDATES
CharactersFolder.ChildAdded:Connect(function(child)
    log("NEW CHILD ADDED: '" .. child.Name .. "' (" .. child.ClassName .. ")")
    if child:IsA("Model") then
        task.wait(1)  -- Wait for full spawn/load
        if isPotentialPlayer(child) then
            addHighlight(child)
        end
    end
end)

CharactersFolder.ChildRemoved:Connect(function(child)
    log("CHILD REMOVED: '" .. child.Name .. "'")
    removeHighlight(child)
end)

-- OWN RESPAWN CLEANUP
LocalPlayer.CharacterAdded:Connect(function()
    log("LOCAL PLAYER RESPAWNED - Cleaning up")
    task.wait(2)
    for char, _ in pairs(highlights) do
        removeHighlight(char)
    end
    -- Re-scan
    for _, child in ipairs(CharactersFolder:GetChildren()) do
        if child:IsA("Model") and isPotentialPlayer(child) then
            addHighlight(child)
        end
    end
end)

log("DEBUG ESP LOADED! GREEN HIGHLIGHTS if players found. Paste FULL CONSOLE HERE.")
log("If no 'ADDED HIGHLIGHT' prints, no valid players detected.")
log("Your own char path: " .. tostring(LocalPlayer.Character))