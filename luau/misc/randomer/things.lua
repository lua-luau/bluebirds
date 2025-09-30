-- LocalScript for Roblox Luau: Draws skeletons on other players (R6 and R15) using Drawing library
-- Toggle with 'T' key. Client-side ESP, polished with efficient updates and cleanup.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local enabled = false
local skeletons = {}  -- {player = {lines = {{part1Name, part2Name, lineObj}, ...}, rigType = "R6" or "R15"}}

-- Define bone connections for R6 and R15
local boneConfigs = {
    R6 = {
        {"Head", "Torso"},
        {"Torso", "Right Arm"},
        {"Torso", "Left Arm"},
        {"Torso", "Right Leg"},
        {"Torso", "Left Leg"},
    },
    R15 = {
        {"Head", "UpperTorso"},
        {"UpperTorso", "LowerTorso"},
        {"UpperTorso", "RightUpperArm"},
        {"RightUpperArm", "RightLowerArm"},
        {"RightLowerArm", "RightHand"},
        {"UpperTorso", "LeftUpperArm"},
        {"LeftUpperArm", "LeftLowerArm"},
        {"LeftLowerArm", "LeftHand"},
        {"LowerTorso", "RightUpperLeg"},
        {"RightUpperLeg", "RightLowerLeg"},
        {"RightLowerLeg", "RightFoot"},
        {"LowerTorso", "LeftUpperLeg"},
        {"LeftUpperLeg", "LeftLowerLeg"},
        {"LeftLowerLeg", "LeftFoot"},
    }
}

-- Function to determine rig type (R6 or R15)
local function getRigType(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        return humanoid.RigType == Enum.HumanoidRigType.R15 and "R15" or "R6"
    end
    return "R6"  -- Default to R6 if humanoid not found
end

-- Function to create skeleton drawing objects for a character
local function createSkeleton(character)
    local rigType = getRigType(character)
    local bones = boneConfigs[rigType]
    local lines = {}
    
    for _, bone in ipairs(bones) do
        local line = Drawing.new("Line")
        line.Visible = false
        line.Color = Color3.fromRGB(255, 255, 255)  -- White
        line.Thickness = 1.5
        line.Transparency = 1
        table.insert(lines, {bone[1], bone[2], line})
    end
    
    return {lines = lines, rigType = rigType}
end

-- Function to update skeleton visibility and positions
local function updateSkeleton(player, character, skeletonData)
    local lines = skeletonData.lines
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        for _, lineData in ipairs(lines) do
            lineData[3].Visible = false
        end
        return
    end
    
    for _, lineData in ipairs(lines) do
        local part1 = character:FindFirstChild(lineData[1])
        local part2 = character:FindFirstChild(lineData[2])
        local line = lineData[3]
        
        if part1 and part2 then
            local pos1, onScreen1 = Camera:WorldToViewportPoint(part1.Position)
            local pos2, onScreen2 = Camera:WorldToViewportPoint(part2.Position)
            
            if onScreen1 and onScreen2 then
                line.From = Vector2.new(pos1.X, pos1.Y)
                line.To = Vector2.new(pos2.X, pos2.Y)
                line.Visible = enabled
            else
                line.Visible = false
            end
        else
            line.Visible = false
        end
    end
end

-- Setup for existing players (exclude local player)
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        player.CharacterAdded:Connect(function(char)
            skeletons[player] = createSkeleton(char)
        end)
        if player.Character then
            skeletons[player] = createSkeleton(player.Character)
        end
    end
end

-- Handle new players joining
Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        player.CharacterAdded:Connect(function(char)
            skeletons[player] = createSkeleton(char)
        end)
        if player.Character then
            skeletons[player] = createSkeleton(player.Character)
        end
    end
end)

-- Cleanup when players leave
Players.PlayerRemoving:Connect(function(player)
    if skeletons[player] then
        for _, lineData in ipairs(skeletons[player].lines) do
            lineData[3]:Remove()
        end
        skeletons[player] = nil
    end
end)

-- Handle character model changes (e.g., R6 to R15 switch)
local function onCharacterAppearanceChanged(player)
    if player ~= LocalPlayer and player.Character then
        if skeletons[player] then
            -- Remove old skeleton
            for _, lineData in ipairs(skeletons[player].lines) do
                lineData[3]:Remove()
            end
        end
        -- Create new skeleton for updated character
        skeletons[player] = createSkeleton(player.Character)
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        player.CharacterAppearanceLoaded:Connect(function(char)
            onCharacterAppearanceChanged(player)
        end)
    end
end
Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        player.CharacterAppearanceLoaded:Connect(function(char)
            onCharacterAppearanceChanged(player)
        end)
    end
end)

-- Toggle functionality (press 'T')
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.T then
        enabled = not enabled
        if not enabled then
            -- Hide all skeletons immediately
            for _, skeletonData in pairs(skeletons) do
                for _, lineData in ipairs(skeletonData.lines) do
                    lineData[3].Visible = false
                end
            end
        end
        print("Skeleton ESP: " .. (enabled and "Enabled" or "Disabled"))
    end
end)

-- Update loop (runs every frame when enabled)
RunService.RenderStepped:Connect(function()
    if not enabled then return end
    for player, skeletonData in pairs(skeletons) do
        local character = player.Character
        if character then
            updateSkeleton(player, character, skeletonData)
        end
    end
end)