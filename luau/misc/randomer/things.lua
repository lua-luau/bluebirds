-- LocalScript for Roblox Luau: Draws skeletons on other players (R6 and R15) using Drawing library
-- Toggle ESP with ']' key. Toggle rainbow mode with '[' key.
-- Press 'T' to toggle camera zoom (magnified scope, persists through aiming).
-- Settings via getgenv().ESPSettings for reloading. Includes TeamCheck.
-- Client-side ESP with debug prints for troubleshooting.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Settings via getgenv() for reloadability
getgenv().ESPSettings = getgenv().ESPSettings or {
    Enabled = false,
    RainbowEnabled = false,
    TeamCheck = true,  -- If true, don't draw on teammates
    RainbowSpeed = 1,  -- Speed of rainbow cycle (higher = faster)
    LineThickness = 1.5,
    LineColor = Color3.fromRGB(255, 255, 255),  -- Default color if not rainbow
    ZoomEnabled = false,
    NormalFOV = Camera.FieldOfView,  -- Store default FOV
    ZoomedFOV = 20  -- Magnified scope FOV
}

local settings = getgenv().ESPSettings
local skeletons = {}  -- {player = {lines = {{part1Name, part2Name, line}, ...}, rigType = "R6" or "R15"}}

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
    return "R6"
end

-- Function to create skeleton drawing objects
local function createSkeleton(character)
    local rigType = getRigType(character)
    local bones = boneConfigs[rigType]
    local lines = {}
    print("Creating skeleton for", character.Name, "RigType:", rigType)
    
    for _, bone in ipairs(bones) do
        local line = Drawing.new("Line")
        line.Visible = false
        line.Color = settings.LineColor
        line.Thickness = settings.LineThickness
        line.Transparency = 1
        table.insert(lines, {part1Name = bone[1], part2Name = bone[2], line = line})
        print("Created line for", bone[1], "to", bone[2])
    end
    
    return {lines = lines, rigType = rigType}
end

-- Function to get rainbow color
local function getRainbowColor()
    local time = tick() * settings.RainbowSpeed
    local r = math.sin(time) * 127 + 128
    local g = math.sin(time + math.pi * 2 / 3) * 127 + 128
    local b = math.sin(time + math.pi * 4 / 3) * 127 + 128
    return Color3.fromRGB(r, g, b)
end

-- Function to update skeleton
local function updateSkeleton(player, character, skeletonData)
    if settings.TeamCheck and player.Team == LocalPlayer.Team then
        print("Skipping", player.Name, "due to team check")
        for _, lineData in ipairs(skeletonData.lines) do
            lineData.line.Visible = false
        end
        return
    end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        print("Skipping", player.Name, "due to no humanoid or dead")
        for _, lineData in ipairs(skeletonData.lines) do
            lineData.line.Visible = false
        end
        return
    end
    
    local color = settings.RainbowEnabled and getRainbowColor() or settings.LineColor
    
    for _, lineData in ipairs(skeletonData.lines) do
        local part1 = character:FindFirstChild(lineData.part1Name)
        local part2 = character:FindFirstChild(lineData.part2Name)
        local line = lineData.line
        
        line.Color = color
        line.Thickness = settings.LineThickness
        
        if part1 and part2 then
            local pos1, onScreen1 = Camera:WorldToViewportPoint(part1.Position)
            local pos2, onScreen2 = Camera:WorldToViewportPoint(part2.Position)
            
            if onScreen1 and onScreen2 and settings.Enabled then
                line.From = Vector2.new(pos1.X, pos1.Y)
                line.To = Vector2.new(pos2.X, pos2.Y)
                line.Visible = true
                -- print("Drawing line for", player.Name, lineData.part1Name, "to", lineData.part2Name)
            else
                line.Visible = false
                if not onScreen1 or not onScreen2 then
                    -- print("Line not visible for", player.Name, "due to off-screen")
                end
            end
        else
            line.Visible = false
            print("Missing parts for", player.Name, ":", lineData.part1Name, lineData.part2Name)
        end
    end
end

-- Setup for existing players (exclude local player)
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        player.CharacterAdded:Connect(function(char)
            skeletons[player] = createSkeleton(char)
            print("Character added for", player.Name)
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
            print("New player", player.Name, "added")
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
            lineData.line:Remove()
        end
        skeletons[player] = nil
        print("Cleaned up skeleton for", player.Name)
    end
end)

-- Handle character model changes (e.g., R6 to R15)
local function onCharacterAppearanceChanged(player)
    if player ~= LocalPlayer and player.Character then
        if skeletons[player] then
            for _, lineData in ipairs(skeletons[player].lines) do
                lineData.line:Remove()
            end
        end
        skeletons[player] = createSkeleton(player.Character)
        print("Updated skeleton for", player.Name)
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

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    local keyCode = input.KeyCode
    
    if keyCode == Enum.KeyCode.RightBracket then  -- ']' to toggle ESP
        settings.Enabled = not settings.Enabled
        if not settings.Enabled then
            for _, skeletonData in pairs(skeletons) do
                for _, lineData in ipairs(skeletonData.lines) do
                    lineData.line.Visible = false
                end
            end
        end
        print("Skeleton ESP: " .. (settings.Enabled and "Enabled" or "Disabled"))
    elseif keyCode == Enum.KeyCode.LeftBracket then  -- '[' to toggle rainbow
        settings.RainbowEnabled = not settings.RainbowEnabled
        print("Rainbow ESP: " .. (settings.RainbowEnabled and "Enabled" or "Disabled"))
    elseif keyCode == Enum.KeyCode.T then  -- 'T' to toggle zoom
        settings.ZoomEnabled = not settings.ZoomEnabled
        print("Camera Zoom: " .. (settings.ZoomEnabled and "Enabled" or "Disabled"))
    end
end)

-- Update loop
RunService.RenderStepped:Connect(function()
    -- Enforce zoom FOV to persist through in-game aiming
    if settings.ZoomEnabled then
        Camera.FieldOfView = settings.ZoomedFOV
    else
        Camera.FieldOfView = settings.NormalFOV
    end
    
    -- Update skeletons
    if not settings.Enabled then
        for _, skeletonData in pairs(skeletons) do
            for _, lineData in ipairs(skeletonData.lines) do
                lineData.line.Visible = false
            end
        end
        return
    end
    
    for player, skeletonData in pairs(skeletons) do
        local character = player.Character
        if character then
            updateSkeleton(player, character, skeletonData)
        end
    end
end)