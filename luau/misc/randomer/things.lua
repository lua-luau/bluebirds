local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Config = {
    ShowSkeleton = true,
    ShowName = true,
    ShowDistance = true,
    ShowHealthBar = true,
    ShowChams = true,
    Rainbow = false,
    TeamCheck = true,
    HealthCheck = true,
    SkeletonColor = Color3.fromRGB(0, 255, 255),
    ChamsColor = Color3.fromRGB(255, 0, 255),
    SkeletonThickness = 2,
    TextSize = 14,
    ChamsTransparency = 0.5,
}

local ESPData = {}
local DrawingPools = {
    Lines = {},
    Texts = {},
}
local Connections = {}
local IsRunning = true

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window = Rayfield:CreateWindow({
    Name = "🎯 ESP Hub",
    LoadingTitle = "ESP Script",
    LoadingSubtitle = "Initializing...",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "ESPHub",
        FileName = "Config"
    },
})

local MainTab = Window:CreateTab("Main", 4483362458)
local SettingsTab = Window:CreateTab("Settings", 4483362458)
local CustomizeTab = Window:CreateTab("Customize", 4483362458)

MainTab:CreateToggle({
    Name = "Show Skeleton",
    CurrentValue = Config.ShowSkeleton,
    Callback = function(v) Config.ShowSkeleton = v end,
})

MainTab:CreateToggle({
    Name = "Show Names",
    CurrentValue = Config.ShowName,
    Callback = function(v) Config.ShowName = v end,
})

MainTab:CreateToggle({
    Name = "Show Distance",
    CurrentValue = Config.ShowDistance,
    Callback = function(v) Config.ShowDistance = v end,
})

MainTab:CreateToggle({
    Name = "Show Health Bar",
    CurrentValue = Config.ShowHealthBar,
    Callback = function(v) Config.ShowHealthBar = v end,
})

MainTab:CreateToggle({
    Name = "Show Chams",
    CurrentValue = Config.ShowChams,
    Callback = function(v) Config.ShowChams = v end,
})

MainTab:CreateToggle({
    Name = "Rainbow Mode",
    CurrentValue = Config.Rainbow,
    Callback = function(v) Config.Rainbow = v end,
})

SettingsTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = Config.TeamCheck,
    Callback = function(v) Config.TeamCheck = v end,
})

SettingsTab:CreateToggle({
    Name = "Health Check",
    CurrentValue = Config.HealthCheck,
    Callback = function(v) Config.HealthCheck = v end,
})

CustomizeTab:CreateSlider({
    Name = "Text Size",
    Range = {8, 24},
    Increment = 1,
    CurrentValue = Config.TextSize,
    Callback = function(v)
        Config.TextSize = v
        for _, data in pairs(ESPData) do
            data.NameText.Size = v
            data.DistanceText.Size = v
            data.HealthText.Size = v
        end
    end,
})

CustomizeTab:CreateSlider({
    Name = "Skeleton Thickness",
    Range = {1, 5},
    Increment = 1,
    CurrentValue = Config.SkeletonThickness,
    Callback = function(v)
        Config.SkeletonThickness = v
        for _, data in pairs(ESPData) do
            for _, lineData in ipairs(data.Skeleton) do
                lineData.Line.Thickness = v
            end
        end
    end,
})

CustomizeTab:CreateSlider({
    Name = "Chams Transparency",
    Range = {0, 1},
    Increment = 0.1,
    CurrentValue = Config.ChamsTransparency,
    Callback = function(v)
        Config.ChamsTransparency = v
        for _, data in pairs(ESPData) do
            if data.Chams then
                for _, highlight in pairs(data.Chams) do
                    highlight.FillTransparency = v
                end
            end
        end
    end,
})

local function CreateLine()
    local line = Drawing.new("Line")
    line.Thickness = Config.SkeletonThickness
    line.Transparency = 1
    line.Visible = false
    return line
end

local function CreateText()
    local text = Drawing.new("Text")
    text.Size = Config.TextSize
    text.Center = true
    text.Outline = true
    text.Font = 2
    text.Color = Color3.new(1, 1, 1)
    text.Visible = false
    return text
end

local function GetLine()
    return table.remove(DrawingPools.Lines) or CreateLine()
end

local function GetText()
    return table.remove(DrawingPools.Texts) or CreateText()
end

local function ReturnLine(line)
    line.Visible = false
    table.insert(DrawingPools.Lines, line)
end

local function ReturnText(text)
    text.Visible = false
    table.insert(DrawingPools.Texts, text)
end

local function CreateChams(character)
    local chams = {}
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local highlight = Instance.new("Highlight")
            highlight.FillColor = Config.ChamsColor
            highlight.OutlineColor = Color3.new(0, 0, 0)
            highlight.FillTransparency = Config.ChamsTransparency
            highlight.OutlineTransparency = 0
            highlight.Adornee = part
            highlight.Parent = part
            table.insert(chams, highlight)
        end
    end
    return chams
end

local function RemoveChams(chams)
    if not chams then return end
    for _, highlight in pairs(chams) do
        if highlight and highlight.Parent then
            highlight:Destroy()
        end
    end
end

local function GetCharacterParts(character)
    if not character then return nil end
    
    local parts = {
        Head = character:FindFirstChild("Head"),
        UpperTorso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"),
        LeftUpperArm = character:FindFirstChild("LeftUpperArm") or character:FindFirstChild("Left Arm"),
        RightUpperArm = character:FindFirstChild("RightUpperArm") or character:FindFirstChild("Right Arm"),
        LeftUpperLeg = character:FindFirstChild("LeftUpperLeg") or character:FindFirstChild("Left Leg"),
        RightUpperLeg = character:FindFirstChild("RightUpperLeg") or character:FindFirstChild("Right Leg"),
    }
    
    for _, part in pairs(parts) do
        if not part then return nil end
    end
    
    return parts
end

local function IsValidTarget(player)
    if player == LocalPlayer then return false end
    
    local character = player.Character
    if not character then return false end
    
    if Config.TeamCheck and player.Team == LocalPlayer.Team then
        return false
    end
    
    if Config.HealthCheck then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then
            return false
        end
    end
    
    return true
end

local function CreateESP(player)
    if ESPData[player] then return end
    
    local data = {
        Player = player,
        Skeleton = {},
        NameText = GetText(),
        DistanceText = GetText(),
        HealthText = GetText(),
        Chams = nil,
        Connections = {},
    }
    
    ESPData[player] = data
    
    local character = player.Character
    if character and Config.ShowChams then
        data.Chams = CreateChams(character)
    end
    
    table.insert(data.Connections, player.CharacterAdded:Connect(function(newCharacter)
        task.wait(0.5)
        RemoveESP(player)
        CreateESP(player)
    end))
    
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            table.insert(data.Connections, humanoid.Died:Connect(function()
                RemoveESP(player)
            end))
        end
    end
end

function RemoveESP(player)
    local data = ESPData[player]
    if not data then return end
    
    for _, conn in ipairs(data.Connections) do
        if conn.Connected then
            conn:Disconnect()
        end
    end
    
    for _, lineData in ipairs(data.Skeleton) do
        ReturnLine(lineData.Line)
    end
    
    ReturnText(data.NameText)
    ReturnText(data.DistanceText)
    ReturnText(data.HealthText)
    
    RemoveChams(data.Chams)
    
    ESPData[player] = nil
end

local function UpdateSkeleton(player, data)
    local character = player.Character
    if not character then return end
    
    local parts = GetCharacterParts(character)
    if not parts then return end
    
    local skeletonPairs = {
        {parts.Head, parts.UpperTorso},
        {parts.UpperTorso, parts.LeftUpperArm},
        {parts.UpperTorso, parts.RightUpperArm},
        {parts.UpperTorso, parts.LeftUpperLeg},
        {parts.UpperTorso, parts.RightUpperLeg},
    }
    
    if #data.Skeleton == 0 then
        for _, pair in ipairs(skeletonPairs) do
            table.insert(data.Skeleton, {
                Part1 = pair[1],
                Part2 = pair[2],
                Line = GetLine(),
            })
        end
    end
    
    local color = Config.Rainbow and Color3.fromHSV((tick() % 5) / 5, 1, 1) or Config.SkeletonColor
    
    for _, lineData in ipairs(data.Skeleton) do
        local part1, part2 = lineData.Part1, lineData.Part2
        
        if not (part1 and part2 and part1.Parent and part2.Parent) then
            lineData.Line.Visible = false
            continue
        end
        
        local pos1, onScreen1 = Camera:WorldToViewportPoint(part1.Position)
        local pos2, onScreen2 = Camera:WorldToViewportPoint(part2.Position)
        
        if onScreen1 and onScreen2 and Config.ShowSkeleton then
            lineData.Line.From = Vector2.new(pos1.X, pos1.Y)
            lineData.Line.To = Vector2.new(pos2.X, pos2.Y)
            lineData.Line.Color = color
            lineData.Line.Visible = true
        else
            lineData.Line.Visible = false
        end
    end
end

local function UpdateText(player, data)
    local character = player.Character
    if not character then
        data.NameText.Visible = false
        data.DistanceText.Visible = false
        data.HealthText.Visible = false
        return
    end
    
    local head = character:FindFirstChild("Head")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not head then
        data.NameText.Visible = false
        data.DistanceText.Visible = false
        data.HealthText.Visible = false
        return
    end
    
    local headPos, onScreen = Camera:WorldToViewportPoint(head.Position)
    
    if not onScreen then
        data.NameText.Visible = false
        data.DistanceText.Visible = false
        data.HealthText.Visible = false
        return
    end
    
    local yOffset = -30
    
    if Config.ShowName then
        data.NameText.Text = player.Name
        data.NameText.Position = Vector2.new(headPos.X, headPos.Y + yOffset)
        data.NameText.Color = player.TeamColor.Color
        data.NameText.Size = Config.TextSize
        data.NameText.Visible = true
        yOffset = yOffset + 15
    else
        data.NameText.Visible = false
    end
    
    if Config.ShowDistance then
        local distance = (head.Position - Camera.CFrame.Position).Magnitude
        data.DistanceText.Text = string.format("%d studs", math.floor(distance))
        data.DistanceText.Position = Vector2.new(headPos.X, headPos.Y + yOffset)
        data.DistanceText.Color = Color3.new(1, 1, 1)
        data.DistanceText.Size = Config.TextSize
        data.DistanceText.Visible = true
        yOffset = yOffset + 15
    else
        data.DistanceText.Visible = false
    end
    
    if Config.ShowHealthBar and humanoid then
        local healthPercent = math.floor((humanoid.Health / humanoid.MaxHealth) * 100)
        local healthColor = Color3.fromRGB(
            math.clamp(255 - (healthPercent * 2.55), 0, 255),
            math.clamp(healthPercent * 2.55, 0, 255),
            0
        )
        data.HealthText.Text = string.format("HP: %d%%", healthPercent)
        data.HealthText.Position = Vector2.new(headPos.X, headPos.Y + yOffset)
        data.HealthText.Color = healthColor
        data.HealthText.Size = Config.TextSize
        data.HealthText.Visible = true
    else
        data.HealthText.Visible = false
    end
end

local function UpdateChams(player, data)
    if Config.ShowChams then
        if not data.Chams and player.Character then
            data.Chams = CreateChams(player.Character)
        end
        if data.Chams then
            local color = Config.Rainbow and Color3.fromHSV((tick() % 5) / 5, 1, 1) or Config.ChamsColor
            for _, highlight in pairs(data.Chams) do
                if highlight and highlight.Parent then
                    highlight.FillColor = color
                    highlight.FillTransparency = Config.ChamsTransparency
                end
            end
        end
    else
        if data.Chams then
            RemoveChams(data.Chams)
            data.Chams = nil
        end
    end
end

local function UpdateESP()
    for player, data in pairs(ESPData) do
        if not IsValidTarget(player) then
            for _, lineData in ipairs(data.Skeleton) do
                lineData.Line.Visible = false
            end
            data.NameText.Visible = false
            data.DistanceText.Visible = false
            data.HealthText.Visible = false
            if data.Chams then
                RemoveChams(data.Chams)
                data.Chams = nil
            end
        else
            UpdateSkeleton(player, data)
            UpdateText(player, data)
            UpdateChams(player, data)
        end
    end
end

local function OnPlayerAdded(player)
    if player == LocalPlayer then return end
    task.wait(0.5)
    CreateESP(player)
end

local function OnPlayerRemoving(player)
    RemoveESP(player)
end

for _, player in ipairs(Players:GetPlayers()) do
    OnPlayerAdded(player)
end

table.insert(Connections, Players.PlayerAdded:Connect(OnPlayerAdded))
table.insert(Connections, Players.PlayerRemoving:Connect(OnPlayerRemoving))
table.insert(Connections, RunService.RenderStepped:Connect(UpdateESP))

task.spawn(function()
    while IsRunning do
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and not ESPData[player] then
                CreateESP(player)
            end
        end
        task.wait(2)
    end
end)

local function Unload()
    IsRunning = false
    
    for _, conn in ipairs(Connections) do
        if conn.Connected then
            conn:Disconnect()
        end
    end
    
    for player in pairs(ESPData) do
        RemoveESP(player)
    end
    
    for _, line in ipairs(DrawingPools.Lines) do
        pcall(function() line:Remove() end)
    end
    
    for _, text in ipairs(DrawingPools.Texts) do
        pcall(function() text:Remove() end)
    end
    
    pcall(function() Rayfield:Destroy() end)
    
    table.clear(ESPData)
    table.clear(DrawingPools.Lines)
    table.clear(DrawingPools.Texts)
    table.clear(Connections)
    
    print("ESP Script Unloaded Successfully")
end

SettingsTab:CreateButton({
    Name = "🔴 Unload Script",
    Callback = Unload
})

print("ESP Script Loaded Successfully")