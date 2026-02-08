-- Optimized ESP Script v3.0
-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Configuration
local Config = {
    -- Visual Elements
    Skeleton = true,
    Box = false,
    Tracers = false,
    ViewAngle = false,
    
    -- Information Display
    Name = true,
    Distance = true,
    Health = true,
    Weapon = false,
    
    -- Filters
    TeamCheck = true,
    HealthCheck = true,
    MaxDistance = 500,
    
    -- Colors
    Rainbow = false,
    SkeletonColor = Color3.fromRGB(0, 255, 255),
    BoxColor = Color3.fromRGB(255, 255, 255),
    TracerColor = Color3.fromRGB(255, 255, 0),
    
    -- Settings
    Thickness = 2,
    TextSize = 14,
    TracerOrigin = "Bottom",
}

-- State
local ESPObjects = {}
local ObjectPool = {Lines = {}, Texts = {}}

-- Object Pool Management
local function GetPooledObject(pool, constructor)
    return table.remove(pool) or constructor()
end

local function ReturnToPool(pool, object)
    object.Visible = false
    table.insert(pool, object)
end

local function CreateLine()
    local line = Drawing.new("Line")
    line.Thickness = Config.Thickness
    line.Transparency = 1
    line.Visible = false
    return line
end

local function CreateText()
    local text = Drawing.new("Text")
    text.Center = true
    text.Outline = true
    text.Font = 2
    text.Size = Config.TextSize
    text.Visible = false
    return text
end

-- Character Utilities
local function GetCharacterParts(character)
    local parts = {
        Head = character:FindFirstChild("Head"),
        Torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"),
        LeftArm = character:FindFirstChild("LeftUpperArm") or character:FindFirstChild("Left Arm"),
        RightArm = character:FindFirstChild("RightUpperArm") or character:FindFirstChild("Right Arm"),
        LeftLeg = character:FindFirstChild("LeftUpperLeg") or character:FindFirstChild("Left Leg"),
        RightLeg = character:FindFirstChild("RightUpperLeg") or character:FindFirstChild("Right Leg"),
        Root = character:FindFirstChild("HumanoidRootPart"),
    }
    
    for _, part in pairs(parts) do
        if not part then return nil end
    end
    
    return parts
end

local function ShouldShowPlayer(player)
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
    
    local root = character:FindFirstChild("HumanoidRootPart")
    if root then
        local distance = (root.Position - Camera.CFrame.Position).Magnitude
        if distance > Config.MaxDistance then
            return false
        end
    end
    
    return true
end

-- Drawing Functions
local function DrawLine(from, to, color, thickness)
    local line = GetPooledObject(ObjectPool.Lines, CreateLine)
    line.From = from
    line.To = to
    line.Color = color
    line.Thickness = thickness or Config.Thickness
    line.Visible = true
    return line
end

local function DrawText(text, position, color, size)
    local textObj = GetPooledObject(ObjectPool.Texts, CreateText)
    textObj.Text = text
    textObj.Position = position
    textObj.Color = color
    textObj.Size = size or Config.TextSize
    textObj.Visible = true
    return textObj
end

local function GetRainbowColor()
    return Color3.fromHSV((tick() % 5) / 5, 1, 1)
end

-- ESP Components
local function UpdateSkeleton(player, parts, drawnObjects)
    if not Config.Skeleton then return end
    
    local color = Config.Rainbow and GetRainbowColor() or Config.SkeletonColor
    local pairs = {
        {parts.Head, parts.Torso},
        {parts.Torso, parts.LeftArm},
        {parts.Torso, parts.RightArm},
        {parts.Torso, parts.LeftLeg},
        {parts.Torso, parts.RightLeg},
    }
    
    for _, pair in ipairs(pairs) do
        local pos1, vis1 = Camera:WorldToViewportPoint(pair[1].Position)
        local pos2, vis2 = Camera:WorldToViewportPoint(pair[2].Position)
        
        if vis1 and vis2 then
            local line = DrawLine(
                Vector2.new(pos1.X, pos1.Y),
                Vector2.new(pos2.X, pos2.Y),
                color
            )
            table.insert(drawnObjects, line)
        end
    end
end

local function UpdateBox(parts, drawnObjects)
    if not Config.Box then return end
    
    local head = parts.Head
    local torso = parts.Torso
    local leftLeg = parts.LeftLeg
    local rightLeg = parts.RightLeg
    
    local topY = head.Position.Y + (head.Size.Y / 2)
    local bottomY = math.min(
        leftLeg.Position.Y - (leftLeg.Size.Y / 2),
        rightLeg.Position.Y - (rightLeg.Size.Y / 2)
    )
    local centerX, centerZ = torso.Position.X, torso.Position.Z
    local width = torso.Size.X * 1.5
    
    local corners = {
        Vector3.new(centerX - width/2, topY, centerZ),
        Vector3.new(centerX + width/2, topY, centerZ),
        Vector3.new(centerX + width/2, bottomY, centerZ),
        Vector3.new(centerX - width/2, bottomY, centerZ),
    }
    
    local screenCorners = {}
    for _, corner in ipairs(corners) do
        local pos, vis = Camera:WorldToViewportPoint(corner)
        if not vis then return end
        table.insert(screenCorners, Vector2.new(pos.X, pos.Y))
    end
    
    local color = Config.Rainbow and GetRainbowColor() or Config.BoxColor
    for i = 1, 4 do
        local line = DrawLine(screenCorners[i], screenCorners[i % 4 + 1], color)
        table.insert(drawnObjects, line)
    end
end

local function UpdateTracer(root, drawnObjects)
    if not Config.Tracers then return end
    
    local pos, vis = Camera:WorldToViewportPoint(root.Position)
    if not vis then return end
    
    local screenSize = Camera.ViewportSize
    local origin = Config.TracerOrigin == "Top" and Vector2.new(screenSize.X / 2, 0)
        or Config.TracerOrigin == "Middle" and Vector2.new(screenSize.X / 2, screenSize.Y / 2)
        or Vector2.new(screenSize.X / 2, screenSize.Y)
    
    local color = Config.Rainbow and GetRainbowColor() or Config.TracerColor
    local line = DrawLine(origin, Vector2.new(pos.X, pos.Y), color)
    table.insert(drawnObjects, line)
end

local function UpdateViewAngle(root, drawnObjects)
    if not Config.ViewAngle then return end
    
    local lookVector = root.CFrame.LookVector * 5
    local endPos = root.Position + lookVector
    
    local pos1, vis1 = Camera:WorldToViewportPoint(root.Position)
    local pos2, vis2 = Camera:WorldToViewportPoint(endPos)
    
    if vis1 and vis2 then
        local line = DrawLine(
            Vector2.new(pos1.X, pos1.Y),
            Vector2.new(pos2.X, pos2.Y),
            Color3.fromRGB(255, 255, 0)
        )
        table.insert(drawnObjects, line)
    end
end

local function UpdateInformation(player, parts, drawnObjects)
    local head = parts.Head
    local root = parts.Root
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    
    local headTop = head.Position + Vector3.new(0, head.Size.Y / 2, 0)
    local headPos, vis = Camera:WorldToViewportPoint(headTop)
    if not vis then return end
    
    local distance = (root.Position - Camera.CFrame.Position).Magnitude
    local scaleFactor = math.clamp(1 - (distance / Config.MaxDistance), 0.4, 1)
    local textSize = math.floor(10 + (18 - 10) * scaleFactor)
    local yOffset = 5
    
    -- Name
    if Config.Name then
        local text = DrawText(
            player.Name,
            Vector2.new(headPos.X, headPos.Y - yOffset),
            player.TeamColor.Color,
            textSize
        )
        table.insert(drawnObjects, text)
        yOffset = yOffset + textSize + 2
    end
    
    -- Distance
    if Config.Distance then
        local text = DrawText(
            string.format("[%d]", math.floor(distance)),
            Vector2.new(headPos.X, headPos.Y - yOffset),
            Color3.new(0.8, 0.8, 0.8),
            textSize
        )
        table.insert(drawnObjects, text)
        yOffset = yOffset + textSize + 2
    end
    
    -- Health
    if Config.Health and humanoid then
        local healthPercent = math.floor((humanoid.Health / humanoid.MaxHealth) * 100)
        local healthColor = Color3.fromRGB(
            math.clamp(255 - healthPercent * 2.55, 0, 255),
            math.clamp(healthPercent * 2.55, 0, 255),
            0
        )
        local text = DrawText(
            string.format("HP: %d%%", healthPercent),
            Vector2.new(headPos.X, headPos.Y - yOffset),
            healthColor,
            textSize
        )
        table.insert(drawnObjects, text)
        yOffset = yOffset + textSize + 2
    end
    
    -- Weapon
    if Config.Weapon then
        local tool = player.Character:FindFirstChildOfClass("Tool")
        local weaponName = tool and tool.Name or "None"
        local text = DrawText(
            weaponName,
            Vector2.new(headPos.X, headPos.Y - yOffset),
            Color3.fromRGB(255, 200, 0),
            textSize
        )
        table.insert(drawnObjects, text)
    end
end

-- Main Update Loop
local function UpdateESP()
    -- Return previous frame's objects to pool
    for _, objects in pairs(ESPObjects) do
        for _, obj in ipairs(objects) do
            if obj.ClassName == "Line" then
                ReturnToPool(ObjectPool.Lines, obj)
            else
                ReturnToPool(ObjectPool.Texts, obj)
            end
        end
    end
    ESPObjects = {}
    
    -- Draw new frame
    for _, player in ipairs(Players:GetPlayers()) do
        if not ShouldShowPlayer(player) then continue end
        
        local parts = GetCharacterParts(player.Character)
        if not parts then continue end
        
        local drawnObjects = {}
        
        UpdateSkeleton(player, parts, drawnObjects)
        UpdateBox(parts, drawnObjects)
        UpdateTracer(parts.Root, drawnObjects)
        UpdateViewAngle(parts.Root, drawnObjects)
        UpdateInformation(player, parts, drawnObjects)
        
        ESPObjects[player] = drawnObjects
    end
end

-- Initialize
local connection = RunService.RenderStepped:Connect(UpdateESP)

-- GUI Setup (Rayfield)
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window = Rayfield:CreateWindow({
    Name = "🎯 ESP Hub v3.0",
    LoadingTitle = "Optimized ESP",
    LoadingSubtitle = "Performance Edition",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "ESPv3",
        FileName = "Config"
    },
})

local VisualsTab = Window:CreateTab("Visuals", 4483362458)
local FiltersTab = Window:CreateTab("Filters", 4483362458)
local ColorsTab = Window:CreateTab("Colors", 4483362458)

-- Visuals
VisualsTab:CreateToggle({Name = "Skeleton", CurrentValue = Config.Skeleton, Callback = function(v) Config.Skeleton = v end})
VisualsTab:CreateToggle({Name = "Box", CurrentValue = Config.Box, Callback = function(v) Config.Box = v end})
VisualsTab:CreateToggle({Name = "Tracers", CurrentValue = Config.Tracers, Callback = function(v) Config.Tracers = v end})
VisualsTab:CreateToggle({Name = "View Angle", CurrentValue = Config.ViewAngle, Callback = function(v) Config.ViewAngle = v end})
VisualsTab:CreateToggle({Name = "Name", CurrentValue = Config.Name, Callback = function(v) Config.Name = v end})
VisualsTab:CreateToggle({Name = "Distance", CurrentValue = Config.Distance, Callback = function(v) Config.Distance = v end})
VisualsTab:CreateToggle({Name = "Health", CurrentValue = Config.Health, Callback = function(v) Config.Health = v end})
VisualsTab:CreateToggle({Name = "Weapon", CurrentValue = Config.Weapon, Callback = function(v) Config.Weapon = v end})

-- Filters
FiltersTab:CreateToggle({Name = "Team Check", CurrentValue = Config.TeamCheck, Callback = function(v) Config.TeamCheck = v end})
FiltersTab:CreateToggle({Name = "Health Check", CurrentValue = Config.HealthCheck, Callback = function(v) Config.HealthCheck = v end})
FiltersTab:CreateSlider({Name = "Max Distance", Range = {100, 2000}, Increment = 50, CurrentValue = Config.MaxDistance, Callback = function(v) Config.MaxDistance = v end})

-- Colors
ColorsTab:CreateToggle({Name = "Rainbow Mode", CurrentValue = Config.Rainbow, Callback = function(v) Config.Rainbow = v end})
ColorsTab:CreateColorPicker({Name = "Skeleton Color", Color = Config.SkeletonColor, Callback = function(v) Config.SkeletonColor = v end})
ColorsTab:CreateColorPicker({Name = "Box Color", Color = Config.BoxColor, Callback = function(v) Config.BoxColor = v end})
ColorsTab:CreateColorPicker({Name = "Tracer Color", Color = Config.TracerColor, Callback = function(v) Config.TracerColor = v end})

-- Cleanup
game:GetService("Players").PlayerRemoving:Connect(function(player)
    if ESPObjects[player] then
        for _, obj in ipairs(ESPObjects[player]) do
            if obj.ClassName == "Line" then
                ReturnToPool(ObjectPool.Lines, obj)
            else
                ReturnToPool(ObjectPool.Texts, obj)
            end
        end
        ESPObjects[player] = nil
    end
end)
