-- Pooling-friendly skeleton ESP
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

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
local skeletons = {} -- player -> skeletonData

local boneConfigs = {
    R6 = {{"Head","Torso"},{"Torso","Right Arm"},{"Torso","Left Arm"},{"Torso","Right Leg"},{"Torso","Left Leg"}},
    R15 = {
        {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
        {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
        {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
        {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
        {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"}
    }
}

local function getRigType(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then return humanoid.RigType == Enum.HumanoidRigType.R15 and "R15" or "R6" end
    return "R6"
end

local function getRainbowColor()
    local t = tick() * settings.RainbowSpeed
    return Color3.fromRGB(
        math.floor(math.sin(t) * 127 + 128),
        math.floor(math.sin(t + 2/3*math.pi) * 127 + 128),
        math.floor(math.sin(t + 4/3*math.pi) * 127 + 128)
    )
end

-- Create skeleton with pooled lines
local function createSkeleton(character)
    local rigType = getRigType(character)
    local bones = boneConfigs[rigType]
    local lines = {}

    for _, bone in ipairs(bones) do
        local line = Drawing.new("Line")
        line.Visible = false
        line.Color = settings.LineColor
        line.Thickness = settings.LineThickness
        line.Transparency = 1
        table.insert(lines, {part1Name = bone[1], part2Name = bone[2], line = line})
    end

    return {lines = lines, rigType = rigType, character = character}
end

-- Update skeleton positions
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
        local p1 = character:FindFirstChild(l.part1Name)
        local p2 = character:FindFirstChild(l.part2Name)
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

-- Reuse existing skeleton lines, don't remove them
local function attachCharacter(player, character)
    if skeletons[player] then
        local skel = skeletons[player]
        skel.character = character
        local rigType = getRigType(character)
        if rigType ~= skel.rigType then
            -- Update bones but reuse lines
            local bones = boneConfigs[rigType]
            for i, bone in ipairs(bones) do
                if skel.lines[i] then
                    skel.lines[i].part1Name = bone[1]
                    skel.lines[i].part2Name = bone[2]
                else
                    local line = Drawing.new("Line")
                    line.Visible = false
                    line.Color = settings.LineColor
                    line.Thickness = settings.LineThickness
                    line.Transparency = 1
                    table.insert(skel.lines, {part1Name=bone[1], part2Name=bone[2], line=line})
                end
            end
            skel.rigType = rigType
        end
    else
        skeletons[player] = createSkeleton(character)
    end
end

-- Player setup
local function setupPlayer(player)
    if player == LocalPlayer then return end
    player.CharacterAdded:Connect(function(char) attachCharacter(player,char) end)
    player.CharacterAppearanceLoaded:Connect(function() if player.Character then attachCharacter(player,player.Character) end end)
    if player.Character then attachCharacter(player,player.Character) end
end

for _, p in ipairs(Players:GetPlayers()) do setupPlayer(p) end
Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(player)
    if skeletons[player] then
        for _, l in ipairs(skeletons[player].lines) do l.line.Visible = false end
        skeletons[player] = nil
    end
end)

-- Input
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightBracket then
        settings.Enabled = not settings.Enabled
    elseif input.KeyCode == Enum.KeyCode.LeftBracket then
        settings.RainbowEnabled = not settings.RainbowEnabled
    elseif input.KeyCode == Enum.KeyCode.T then
        settings.ZoomEnabled = not settings.ZoomEnabled
    end
end)

-- Main loop
RunService.RenderStepped:Connect(function()
    Camera.FieldOfView = settings.ZoomEnabled and settings.ZoomedFOV or settings.NormalFOV
    for player, skel in pairs(skeletons) do
        if skel.character then updateSkeleton(player, skel.character, skel) end
    end
end)