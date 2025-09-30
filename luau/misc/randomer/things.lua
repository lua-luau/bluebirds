--// LocalScript: Player Skeleton ESP (R6 + R15) with Zoom + Rainbow
--// Toggle Keys: ] = ESP | [ = Rainbow | T = Zoom

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Reloadable Settings
getgenv().ESPSettings = getgenv().ESPSettings or {
    Enabled = false,
    RainbowEnabled = false,
    TeamCheck = true,
    RainbowSpeed = 1,
    LineThickness = 1.5,
    LineColor = Color3.fromRGB(255, 255, 255),
    ZoomEnabled = false,
    NormalFOV = Camera.FieldOfView,
    ZoomedFOV = 20
}

local settings = getgenv().ESPSettings
local skeletons = {}

-- Bone configurations
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

--// Helpers
local function safeRemove(drawing)
    if drawing then
        if drawing.Remove then drawing:Remove()
        elseif drawing.Destroy then drawing:Destroy() end
    end
end

local function getRigType(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        return humanoid.RigType == Enum.HumanoidRigType.R15 and "R15" or "R6"
    end
    return "R6"
end

local function getRainbowColor()
    local t = tick() * settings.RainbowSpeed
    local r = math.floor(math.sin(t) * 127 + 128)
    local g = math.floor(math.sin(t + math.pi * 2/3) * 127 + 128)
    local b = math.floor(math.sin(t + math.pi * 4/3) * 127 + 128)
    return Color3.fromRGB(r, g, b)
end

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
    end

    return {lines = lines, rigType = rigType}
end

local function updateSkeleton(player, character, skeletonData)
    if settings.TeamCheck and LocalPlayer.Team and player.Team == LocalPlayer.Team then
        for _, l in ipairs(skeletonData.lines) do l.line.Visible = false end
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        for _, l in ipairs(skeletonData.lines) do l.line.Visible = false end
        return
    end

    local color = settings.RainbowEnabled and getRainbowColor() or settings.LineColor

    for _, l in ipairs(skeletonData.lines) do
        local p1, p2 = character:FindFirstChild(l.part1Name), character:FindFirstChild(l.part2Name)
        local line = l.line
        line.Color = color
        line.Thickness = settings.LineThickness

        if p1 and p2 then
            local pos1, vis1 = Camera:WorldToViewportPoint(p1.Position)
            local pos2, vis2 = Camera:WorldToViewportPoint(p2.Position)
            if vis1 and vis2 and settings.Enabled then
                line.From = Vector2.new(pos1.X, pos1.Y)
                line.To = Vector2.new(pos2.X, pos2.Y)
                line.Visible = true
            else
                line.Visible = false
            end
        else
            line.Visible = false
        end
    end
end

--// Player lifecycle
local function setupPlayer(player)
    if player == LocalPlayer then return end

    local function attach(char)
        if skeletons[player] then
            for _, l in ipairs(skeletons[player].lines) do safeRemove(l.line) end
        end
        skeletons[player] = createSkeleton(char)
    end

    player.CharacterAdded:Connect(attach)
    player.CharacterAppearanceLoaded:Connect(function()
        if player.Character then attach(player.Character) end
    end)

    if player.Character then attach(player.Character) end
end

for _, p in ipairs(Players:GetPlayers()) do setupPlayer(p) end
Players.PlayerAdded:Connect(setupPlayer)

Players.PlayerRemoving:Connect(function(player)
    if skeletons[player] then
        for _, l in ipairs(skeletons[player].lines) do safeRemove(l.line) end
        skeletons[player] = nil
    end
end)

--// Input Handling
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightBracket then
        settings.Enabled = not settings.Enabled
        print("Skeleton ESP:", settings.Enabled)
    elseif input.KeyCode == Enum.KeyCode.LeftBracket then
        settings.RainbowEnabled = not settings.RainbowEnabled
        print("Rainbow ESP:", settings.RainbowEnabled)
    elseif input.KeyCode == Enum.KeyCode.T then
        settings.ZoomEnabled = not settings.ZoomEnabled
        print("Camera Zoom:", settings.ZoomEnabled)
    end
end)

--// Main Update Loop
RunService.RenderStepped:Connect(function()
    Camera.FieldOfView = settings.ZoomEnabled and settings.ZoomedFOV or settings.NormalFOV

    if not settings.Enabled then
        for _, skel in pairs(skeletons) do
            for _, l in ipairs(skel.lines) do l.line.Visible = false end
        end
        return
    end

    for player, skel in pairs(skeletons) do
        local char = player.Character
        if char then updateSkeleton(player, char, skel) end
    end
end)