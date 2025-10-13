local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Config = {
    ShowSkeleton = true,
    ShowName = true,
    ShowDistance = true,
    ShowHealthBar = true,
    ShowBox = false,
    ShowTracers = false,
    ShowWeapon = false,
    ShowViewAngle = false,
    Rainbow = false,
    TeamCheck = true,
    HealthCheck = true,
    DistanceCheck = false,
    MaxDistance = 500,
    SkeletonColor = Color3.fromRGB(0, 255, 255),
    BoxColor = Color3.fromRGB(255, 255, 255),
    TracerColor = Color3.fromRGB(255, 255, 0),
    SkeletonThickness = 2,
    BoxThickness = 2,
    TracerThickness = 2,
    TextSize = 14,
    MinTextSize = 8,
    MaxTextSize = 20,
    TracerOrigin = "Bottom",
    TextOffsetY = 0,
    DistanceUnit = "Studs",
}

local ESPData = {}
local DrawingPools = {Lines = {}, Texts = {}}
local Connections = {}
local IsRunning = true

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window = Rayfield:CreateWindow({
    Name = "🎯 Advanced ESP Hub",
    LoadingTitle = "ESP Script v2.0",
    LoadingSubtitle = "Optimized Edition",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "AdvancedESP",
        FileName = "Config"
    },
})

local VisualsTab = Window:CreateTab("Visuals", 4483362458)
local FiltersTab = Window:CreateTab("Filters", 4483362458)
local SettingsTab = Window:CreateTab("Settings", 4483362458)
local ColorsTab = Window:CreateTab("Colors", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483362458)

local VisualSection = VisualsTab:CreateSection("ESP Elements")

VisualsTab:CreateToggle({
    Name = "Skeleton ESP",
    CurrentValue = Config.ShowSkeleton,
    Callback = function(v) Config.ShowSkeleton = v end,
})

VisualsTab:CreateToggle({
    Name = "Box ESP",
    CurrentValue = Config.ShowBox,
    Callback = function(v) Config.ShowBox = v end,
})

VisualsTab:CreateToggle({
    Name = "Tracers",
    CurrentValue = Config.ShowTracers,
    Callback = function(v) Config.ShowTracers = v end,
})

VisualsTab:CreateToggle({
    Name = "View Angle Lines",
    CurrentValue = Config.ShowViewAngle,
    Callback = function(v) Config.ShowViewAngle = v end,
})

local InfoSection = VisualsTab:CreateSection("Information Display")

VisualsTab:CreateToggle({
    Name = "Player Names",
    CurrentValue = Config.ShowName,
    Callback = function(v) Config.ShowName = v end,
})

VisualsTab:CreateToggle({
    Name = "Distance",
    CurrentValue = Config.ShowDistance,
    Callback = function(v) Config.ShowDistance = v end,
})

VisualsTab:CreateToggle({
    Name = "Health Bar",
    CurrentValue = Config.ShowHealthBar,
    Callback = function(v) Config.ShowHealthBar = v end,
})

VisualsTab:CreateToggle({
    Name = "Weapon Display",
    CurrentValue = Config.ShowWeapon,
    Callback = function(v) Config.ShowWeapon = v end,
})

local FilterSection = FiltersTab:CreateSection("Target Filters")

FiltersTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = Config.TeamCheck,
    Callback = function(v) Config.TeamCheck = v end,
})

FiltersTab:CreateToggle({
    Name = "Health Check (Hide Dead)",
    CurrentValue = Config.HealthCheck,
    Callback = function(v) Config.HealthCheck = v end,
})

FiltersTab:CreateToggle({
    Name = "Distance Check",
    CurrentValue = Config.DistanceCheck,
    Callback = function(v) Config.DistanceCheck = v end,
})

FiltersTab:CreateSlider({
    Name = "Max Distance (studs)",
    Range = {100, 2000},
    Increment = 50,
    CurrentValue = Config.MaxDistance,
    Callback = function(v) Config.MaxDistance = v end,
})

local AppearanceSection = SettingsTab:CreateSection("Appearance Settings")

SettingsTab:CreateSlider({
    Name = "Base Text Size",
    Range = {10, 24},
    Increment = 1,
    CurrentValue = Config.TextSize,
    Callback = function(v) Config.TextSize = v end,
})

SettingsTab:CreateSlider({
    Name = "Min Text Size (Far)",
    Range = {6, 14},
    Increment = 1,
    CurrentValue = Config.MinTextSize,
    Callback = function(v) Config.MinTextSize = v end,
})

SettingsTab:CreateSlider({
    Name = "Max Text Size (Close)",
    Range = {14, 28},
    Increment = 1,
    CurrentValue = Config.MaxTextSize,
    Callback = function(v) Config.MaxTextSize = v end,
})

SettingsTab:CreateSlider({
    Name = "Skeleton Thickness",
    Range = {1, 6},
    Increment = 1,
    CurrentValue = Config.SkeletonThickness,
    Callback = function(v) Config.SkeletonThickness = v end,
})

SettingsTab:CreateSlider({
    Name = "Box Thickness",
    Range = {1, 6},
    Increment = 1,
    CurrentValue = Config.BoxThickness,
    Callback = function(v) Config.BoxThickness = v end,
})

SettingsTab:CreateSlider({
    Name = "Tracer Thickness",
    Range = {1, 6},
    Increment = 1,
    CurrentValue = Config.TracerThickness,
    Callback = function(v) Config.TracerThickness = v end,
})

SettingsTab:CreateSlider({
    Name = "Text Y Offset",
    Range = {-50, 50},
    Increment = 1,
    CurrentValue = Config.TextOffsetY,
    Callback = function(v) Config.TextOffsetY = v end,
})

SettingsTab:CreateDropdown({
    Name = "Distance Unit",
    Options = {"Studs", "Meters"},
    CurrentOption = Config.DistanceUnit,
    Callback = function(v) Config.DistanceUnit = v end,
})

SettingsTab:CreateDropdown({
    Name = "Tracer Origin",
    Options = {"Top", "Middle", "Bottom"},
    CurrentOption = Config.TracerOrigin,
    Callback = function(v) Config.TracerOrigin = v end,
})

local ColorSection = ColorsTab:CreateSection("Color Customization")

ColorsTab:CreateToggle({
    Name = "Rainbow Mode",
    CurrentValue = Config.Rainbow,
    Callback = function(v) Config.Rainbow = v end,
})

ColorsTab:CreateColorPicker({
    Name = "Skeleton Color",
    Color = Config.SkeletonColor,
    Callback = function(v) Config.SkeletonColor = v end,
})

ColorsTab:CreateColorPicker({
    Name = "Box Color",
    Color = Config.BoxColor,
    Callback = function(v) Config.BoxColor = v end,
})

ColorsTab:CreateColorPicker({
    Name = "Tracer Color",
    Color = Config.TracerColor,
    Callback = function(v) Config.TracerColor = v end,
})

local function CreateLine()
    local line = Drawing.new("Line")
    line.Thickness = 1
    line.Transparency = 1
    line.Visible = false
    return line
end

local function CreateText()
    local text = Drawing.new("Text")
    text.Size = 14
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

local function CreateBox()
    local box = {}
    for i = 1, 4 do
        table.insert(box, GetLine())
    end
    return box
end

local function RemoveBox(box)
    if not box then return end
    for _, line in ipairs(box) do
        ReturnLine(line)
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
        HumanoidRootPart = character:FindFirstChild("HumanoidRootPart"),
    }
    
    for k, part in pairs(parts) do
        if not part then return nil end
    end
    
    return parts
end

local function GetEquippedTool(character)
    local tool = character:FindFirstChildOfClass("Tool")
    return tool and tool.Name or "None"
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
    
    if Config.DistanceCheck then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local dist = (hrp.Position - Camera.CFrame.Position).Magnitude
            if dist > Config.MaxDistance then
                return false
            end
        end
    end
    
    return true
end

local function CreateESP(player)
    if ESPData[player] then return end
    
    local data = {
        Player = player,
        Skeleton = {},
        Box = nil,
        Tracer = nil,
        ViewAngle = nil,
        NameText = GetText(),
        DistanceText = GetText(),
        HealthText = GetText(),
        WeaponText = GetText(),
        Connections = {},
    }
    
    ESPData[player] = data
    
    table.insert(data.Connections, player.CharacterAdded:Connect(function()
        task.wait(0.5)
        RemoveESP(player)
        CreateESP(player)
    end))
    
    local character = player.Character
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
    
    if data.Box then RemoveBox(data.Box) end
    if data.Tracer then ReturnLine(data.Tracer) end
    if data.ViewAngle then ReturnLine(data.ViewAngle) end
    
    ReturnText(data.NameText)
    ReturnText(data.DistanceText)
    ReturnText(data.HealthText)
    ReturnText(data.WeaponText)
    
    ESPData[player] = nil
end

local function UpdateSkeleton(player, data)
    if not Config.ShowSkeleton then
        for _, lineData in ipairs(data.Skeleton) do
            lineData.Line.Visible = false
        end
        return
    end
    
    local character = player.Character
    if not character then return end
    
    local parts = GetCharacterParts(character)
    if not parts then return end
    
    if #data.Skeleton == 0 then
        local skeletonPairs = {
            {parts.Head, parts.UpperTorso},
            {parts.UpperTorso, parts.LeftUpperArm},
            {parts.UpperTorso, parts.RightUpperArm},
            {parts.UpperTorso, parts.LeftUpperLeg},
            {parts.UpperTorso, parts.RightUpperLeg},
        }
        
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
        
        if onScreen1 and onScreen2 then
            lineData.Line.From = Vector2.new(pos1.X, pos1.Y)
            lineData.Line.To = Vector2.new(pos2.X, pos2.Y)
            lineData.Line.Color = color
            lineData.Line.Thickness = Config.SkeletonThickness
            lineData.Line.Visible = true
        else
            lineData.Line.Visible = false
        end
    end
end

local function UpdateBox(player, data)
    if not Config.ShowBox then
        if data.Box then
            for _, line in ipairs(data.Box) do
                line.Visible = false
            end
        end
        return
    end
    
    local character = player.Character
    if not character then
        if data.Box then
            for _, line in ipairs(data.Box) do
                line.Visible = false
            end
        end
        return
    end
    
    if not data.Box then
        data.Box = CreateBox()
    end
    
    local parts = GetCharacterParts(character)
    if not parts then
        if data.Box then
            for _, line in ipairs(data.Box) do
                line.Visible = false
            end
        end
        return
    end
    
    local head = parts.Head
    local torso = parts.UpperTorso
    local leftLeg = parts.LeftUpperLeg
    local rightLeg = parts.RightUpperLeg
    
    local topY = head.Position.Y + (head.Size.Y / 2)
    local bottomY = math.min(leftLeg.Position.Y - (leftLeg.Size.Y / 2), rightLeg.Position.Y - (rightLeg.Size.Y / 2))
    local centerX = torso.Position.X
    local centerZ = torso.Position.Z
    local width = torso.Size.X * 1.5
    
    local corners = {
        Vector3.new(centerX - width/2, topY, centerZ),
        Vector3.new(centerX + width/2, topY, centerZ),
        Vector3.new(centerX + width/2, bottomY, centerZ),
        Vector3.new(centerX - width/2, bottomY, centerZ),
    }
    
    local screenCorners = {}
    local allVisible = true
    
    for _, corner in ipairs(corners) do
        local pos, visible = Camera:WorldToViewportPoint(corner)
        table.insert(screenCorners, Vector2.new(pos.X, pos.Y))
        if not visible then allVisible = false end
    end
    
    if allVisible then
        local color = Config.Rainbow and Color3.fromHSV((tick() % 5) / 5, 1, 1) or Config.BoxColor
        for i = 1, 4 do
            local line = data.Box[i]
            line.From = screenCorners[i]
            line.To = screenCorners[i % 4 + 1]
            line.Color = color
            line.Thickness = Config.BoxThickness
            line.Visible = true
        end
    else
        for _, line in ipairs(data.Box) do
            line.Visible = false
        end
    end
end

local function UpdateTracer(player, data)
    if not Config.ShowTracers then
        if data.Tracer then data.Tracer.Visible = false end
        return
    end
    
    local character = player.Character
    if not character then
        if data.Tracer then data.Tracer.Visible = false end
        return
    end
    
    if not data.Tracer then
        data.Tracer = GetLine()
    end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        data.Tracer.Visible = false
        return
    end
    
    local pos, visible = Camera:WorldToViewportPoint(hrp.Position)
    if visible then
        local screenSize = Camera.ViewportSize
        local origin
        if Config.TracerOrigin == "Top" then
            origin = Vector2.new(screenSize.X / 2, 0)
        elseif Config.TracerOrigin == "Middle" then
            origin = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
        else
            origin = Vector2.new(screenSize.X / 2, screenSize.Y)
        end
        
        local color = Config.Rainbow and Color3.fromHSV((tick() % 5) / 5, 1, 1) or Config.TracerColor
        data.Tracer.From = origin
        data.Tracer.To = Vector2.new(pos.X, pos.Y)
        data.Tracer.Color = color
        data.Tracer.Thickness = Config.TracerThickness
        data.Tracer.Visible = true
    else
        data.Tracer.Visible = false
    end
end

local function UpdateViewAngle(player, data)
    if not Config.ShowViewAngle then
        if data.ViewAngle then data.ViewAngle.Visible = false end
        return
    end
    
    local character = player.Character
    if not character then
        if data.ViewAngle then data.ViewAngle.Visible = false end
        return
    end
    
    if not data.ViewAngle then
        data.ViewAngle = GetLine()
    end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        data.ViewAngle.Visible = false
        return
    end
    
    local lookVector = hrp.CFrame.LookVector * 5
    local endPos = hrp.Position + lookVector
    
    local pos1, vis1 = Camera:WorldToViewportPoint(hrp.Position)
    local pos2, vis2 = Camera:WorldToViewportPoint(endPos)
    
    if vis1 and vis2 then
        local color = Config.Rainbow and Color3.fromHSV((tick() % 5) / 5, 1, 1) or Color3.fromRGB(255, 255, 0)
        data.ViewAngle.From = Vector2.new(pos1.X, pos1.Y)
        data.ViewAngle.To = Vector2.new(pos2.X, pos2.Y)
        data.ViewAngle.Color = color
        data.ViewAngle.Thickness = 2
        data.ViewAngle.Visible = true
    else
        data.ViewAngle.Visible = false
    end
end

local function UpdateText(player, data)
    local character = player.Character
    if not character then
        data.NameText.Visible = false
        data.DistanceText.Visible = false
        data.HealthText.Visible = false
        data.WeaponText.Visible = false
        return
    end
    
    local head = character:FindFirstChild("Head")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not head or not hrp then
        data.NameText.Visible = false
        data.DistanceText.Visible = false
        data.HealthText.Visible = false
        data.WeaponText.Visible = false
        return
    end
    
    local distance = (hrp.Position - Camera.CFrame.Position).Magnitude
    local centerPos = hrp.Position
    local headPos, onScreen = Camera:WorldToViewportPoint(centerPos)
    
    if not onScreen then
        data.NameText.Visible = false
        data.DistanceText.Visible = false
        data.HealthText.Visible = false
        data.WeaponText.Visible = false
        return
    end
    
    local scaleFactor = math.clamp(1 - (distance / Config.MaxDistance), 0.3, 1)
    local dynamicTextSize = math.floor(Config.MinTextSize + (Config.MaxTextSize - Config.MinTextSize) * scaleFactor)
    
    local yOffset = Config.TextOffsetY
    
    if Config.ShowName then
        data.NameText.Text = player.Name
        data.NameText.Position = Vector2.new(headPos.X, headPos.Y + yOffset)
        data.NameText.Color = player.TeamColor.Color
        data.NameText.Size = dynamicTextSize
        data.NameText.Visible = true
        yOffset = yOffset + dynamicTextSize + 2
    else
        data.NameText.Visible = false
    end
    
    if Config.ShowDistance then
        local displayDistance = distance
        local unit = Config.DistanceUnit
        
        if unit == "Meters" then
            displayDistance = distance * 0.28
        end
        
        data.DistanceText.Text = string.format("[%.1f %s]", displayDistance, unit:lower())
        data.DistanceText.Position = Vector2.new(headPos.X, headPos.Y + yOffset)
        data.DistanceText.Color = Color3.new(0.8, 0.8, 0.8)
        data.DistanceText.Size = dynamicTextSize
        data.DistanceText.Visible = true
        yOffset = yOffset + dynamicTextSize + 2
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
        data.HealthText.Size = dynamicTextSize
        data.HealthText.Visible = true
        yOffset = yOffset + dynamicTextSize + 2
    else
        data.HealthText.Visible = false
    end
    
    if Config.ShowWeapon then
        local weapon = GetEquippedTool(character)
        data.WeaponText.Text = weapon
        data.WeaponText.Position = Vector2.new(headPos.X, headPos.Y + yOffset)
        data.WeaponText.Color = Color3.fromRGB(255, 200, 0)
        data.WeaponText.Size = dynamicTextSize
        data.WeaponText.Visible = true
    else
        data.WeaponText.Visible = false
    end
end

local function UpdateESP()
    for player, data in pairs(ESPData) do
        if not IsValidTarget(player) then
            for _, lineData in ipairs(data.Skeleton) do
                lineData.Line.Visible = false
            end
            if data.Box then
                for _, line in ipairs(data.Box) do
                    line.Visible = false
                end
            end
            if data.Tracer then data.Tracer.Visible = false end
            if data.ViewAngle then data.ViewAngle.Visible = false end
            data.NameText.Visible = false
            data.DistanceText.Visible = false
            data.HealthText.Visible = false
            data.WeaponText.Visible = false
        else
            UpdateSkeleton(player, data)
            UpdateBox(player, data)
            UpdateTracer(player, data)
            UpdateViewAngle(player, data)
            UpdateText(player, data)
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

MiscTab:CreateButton({
    Name = "🔴 Unload Script",
    Callback = Unload
})

MiscTab:CreateButton({
    Name = "💾 Save Configuration",
    Callback = function()
        Rayfield:Notify({
            Title = "Configuration Saved",
            Content = "Your ESP settings have been saved!",
            Duration = 3,
        })
    end
})