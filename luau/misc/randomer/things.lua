-- ═══════════════════════════════════════════════════════════════
--  Premium ESP System v4.0 - Polished Edition
--  High-performance, feature-rich ESP with smooth animations
-- ═══════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════════
--  CONFIGURATION
-- ═══════════════════════════════════════════════════════════════

local Config = {
    -- Visual Elements
    Skeleton = {
        Enabled = true,
        Thickness = 2,
        Color = Color3.fromRGB(0, 255, 255),
        Transparency = 0.9,
    },
    
    Box = {
        Enabled = false,
        Thickness = 2,
        Color = Color3.fromRGB(255, 255, 255),
        Transparency = 0.8,
        Filled = false,
        FilledTransparency = 0.1,
    },
    
    Tracers = {
        Enabled = false,
        Thickness = 1.5,
        Color = Color3.fromRGB(255, 255, 0),
        Transparency = 0.7,
        Origin = "Bottom", -- Top, Middle, Bottom
    },
    
    HealthBar = {
        Enabled = true,
        Width = 3,
        Height = 0, -- Auto-calculated
        Outline = true,
        GradientEnabled = true,
    },
    
    Text = {
        Name = {Enabled = true, Color = Color3.fromRGB(255, 255, 255)},
        Distance = {Enabled = true, Color = Color3.fromRGB(200, 200, 200)},
        Health = {Enabled = true, Color = Color3.fromRGB(255, 255, 255)},
        Weapon = {Enabled = false, Color = Color3.fromRGB(255, 200, 0)},
        Size = 14,
        Font = 2, -- UI, System, Plex, Monospace
        Outline = true,
        ScaleWithDistance = true,
    },
    
    ViewAngle = {
        Enabled = false,
        Length = 6,
        Thickness = 2,
        Color = Color3.fromRGB(255, 0, 0),
    },
    
    -- Advanced Features
    Chams = {
        Enabled = false,
        Transparency = 0.5,
        AlwaysOnTop = true,
        TeamColor = true,
    },
    
    Snaplines = {
        Enabled = false,
        ToHead = true,
        Thickness = 1,
    },
    
    -- Filters
    TeamCheck = true,
    HealthCheck = true,
    VisibilityCheck = false,
    MaxDistance = 500,
    MinDistance = 0,
    
    -- Visual Effects
    Rainbow = {
        Enabled = false,
        Speed = 2, -- Lower = slower
    },
    
    FadeWithDistance = true,
    SmoothUpdates = true,
    UpdateRate = 60, -- FPS cap for ESP updates
    
    -- Performance
    UseOcclusionCulling = true,
    MaxVisiblePlayers = 20,
    
    -- Hotkeys
    ToggleKey = Enum.KeyCode.Insert,
}

-- ═══════════════════════════════════════════════════════════════
--  STATE MANAGEMENT
-- ═══════════════════════════════════════════════════════════════

local ESPData = {}
local ObjectPools = {
    Lines = {},
    Texts = {},
    Quads = {},
}

local State = {
    Enabled = true,
    LastUpdate = 0,
    FrameCount = 0,
    RainbowHue = 0,
}

-- ═══════════════════════════════════════════════════════════════
--  UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════════

local function Lerp(a, b, t)
    return a + (b - a) * t
end

local function GetRainbowColor()
    return Color3.fromHSV(State.RainbowHue, 1, 1)
end

local function GetDistanceColor(distance)
    local normalized = math.clamp(distance / Config.MaxDistance, 0, 1)
    return Color3.fromRGB(
        math.floor(normalized * 255),
        math.floor((1 - normalized) * 255),
        0
    )
end

local function GetHealthColor(healthPercent)
    local r = math.clamp(255 - healthPercent * 2.55, 0, 255)
    local g = math.clamp(healthPercent * 2.55, 0, 255)
    return Color3.fromRGB(r, g, 0)
end

local function WorldToScreen(position)
    local screenPos, onScreen = Camera:WorldToViewportPoint(position)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

local function IsPositionVisible(position)
    if not Config.VisibilityCheck then return true end
    
    local origin = Camera.CFrame.Position
    local direction = (position - origin).Unit * (position - origin).Magnitude
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    
    local result = workspace:Raycast(origin, direction, raycastParams)
    return not result or result.Instance:IsDescendantOf(Players:GetPlayerFromCharacter(result.Instance.Parent) and result.Instance.Parent)
end

-- ═══════════════════════════════════════════════════════════════
--  OBJECT POOLING
-- ═══════════════════════════════════════════════════════════════

local DrawingConstructors = {
    Line = function()
        local line = Drawing.new("Line")
        line.Thickness = 1
        line.Transparency = 1
        line.Visible = false
        return line
    end,
    
    Text = function()
        local text = Drawing.new("Text")
        text.Center = true
        text.Outline = true
        text.Font = Config.Text.Font
        text.Size = Config.Text.Size
        text.Visible = false
        return text
    end,
    
    Quad = function()
        local quad = Drawing.new("Quad")
        quad.Thickness = 1
        quad.Transparency = 1
        quad.Visible = false
        quad.Filled = false
        return quad
    end,
}

local function GetFromPool(poolName, drawingType)
    local pool = ObjectPools[poolName]
    if #pool > 0 then
        return table.remove(pool)
    end
    return DrawingConstructors[drawingType]()
end

local function ReturnToPool(poolName, object)
    if not object then return end
    object.Visible = false
    table.insert(ObjectPools[poolName], object)
end

local function CreateDrawing(drawingType, poolName)
    return GetFromPool(poolName, drawingType)
end

-- ═══════════════════════════════════════════════════════════════
--  CHARACTER UTILITIES
-- ═══════════════════════════════════════════════════════════════

local function GetCharacterParts(character)
    if not character then return nil end
    
    local parts = {
        Head = character:FindFirstChild("Head"),
        Torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"),
        LeftArm = character:FindFirstChild("LeftUpperArm") or character:FindFirstChild("Left Arm"),
        RightArm = character:FindFirstChild("RightUpperArm") or character:FindFirstChild("Right Arm"),
        LeftLeg = character:FindFirstChild("LeftUpperLeg") or character:FindFirstChild("Left Leg"),
        RightLeg = character:FindFirstChild("RightUpperLeg") or character:FindFirstChild("Right Leg"),
        Root = character:FindFirstChild("HumanoidRootPart"),
        
        -- R15 Specific
        LeftLowerArm = character:FindFirstChild("LeftLowerArm"),
        RightLowerArm = character:FindFirstChild("RightLowerArm"),
        LeftLowerLeg = character:FindFirstChild("LeftLowerLeg"),
        RightLowerLeg = character:FindFirstChild("RightLowerLeg"),
        LowerTorso = character:FindFirstChild("LowerTorso"),
    }
    
    -- Validate essential parts
    if not (parts.Head and parts.Torso and parts.Root) then
        return nil
    end
    
    return parts
end

local function GetCharacterBounds(parts)
    local positions = {}
    for _, part in pairs(parts) do
        if part and part:IsA("BasePart") then
            table.insert(positions, part.Position)
        end
    end
    
    if #positions == 0 then return nil end
    
    local minX, minY, minZ = math.huge, math.huge, math.huge
    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
    
    for _, pos in ipairs(positions) do
        minX = math.min(minX, pos.X)
        minY = math.min(minY, pos.Y)
        minZ = math.min(minZ, pos.Z)
        maxX = math.max(maxX, pos.X)
        maxY = math.max(maxY, pos.Y)
        maxZ = math.max(maxZ, pos.Z)
    end
    
    return {
        Min = Vector3.new(minX, minY, minZ),
        Max = Vector3.new(maxX, maxY, maxZ),
        Center = Vector3.new((minX + maxX) / 2, (minY + maxY) / 2, (minZ + maxZ) / 2),
    }
end

local function ShouldShowPlayer(player, distance)
    if player == LocalPlayer then return false end
    if not player.Character then return false end
    
    if Config.TeamCheck and player.Team == LocalPlayer.Team then
        return false
    end
    
    if Config.HealthCheck then
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then
            return false
        end
    end
    
    if distance then
        if distance > Config.MaxDistance or distance < Config.MinDistance then
            return false
        end
    end
    
    return true
end

-- ═══════════════════════════════════════════════════════════════
--  DRAWING FUNCTIONS
-- ═══════════════════════════════════════════════════════════════

local function DrawSkeleton(parts, distance, drawnObjects)
    if not Config.Skeleton.Enabled then return end
    
    local skeletonPairs = {
        -- Torso to extremities
        {parts.Head, parts.Torso},
        {parts.Torso, parts.LeftArm},
        {parts.Torso, parts.RightArm},
        
        -- R15 Arms
        {parts.LeftArm, parts.LeftLowerArm},
        {parts.RightArm, parts.RightLowerArm},
        
        -- Legs
        {parts.Torso, parts.LowerTorso or parts.LeftLeg},
        {parts.LowerTorso or parts.Torso, parts.LeftLeg},
        {parts.LowerTorso or parts.Torso, parts.RightLeg},
        
        -- R15 Legs
        {parts.LeftLeg, parts.LeftLowerLeg},
        {parts.RightLeg, parts.RightLowerLeg},
    }
    
    local color = Config.Rainbow.Enabled and GetRainbowColor() or Config.Skeleton.Color
    local transparency = Config.Skeleton.Transparency
    
    if Config.FadeWithDistance then
        local fadeFactor = 1 - math.clamp(distance / Config.MaxDistance, 0, 1)
        transparency = transparency * fadeFactor
    end
    
    for _, pair in ipairs(skeletonPairs) do
        if not (pair[1] and pair[2]) then continue end
        
        local pos1, vis1 = WorldToScreen(pair[1].Position)
        local pos2, vis2 = WorldToScreen(pair[2].Position)
        
        if vis1 and vis2 then
            local line = CreateDrawing("Line", "Lines")
            line.From = pos1
            line.To = pos2
            line.Color = color
            line.Thickness = Config.Skeleton.Thickness
            line.Transparency = transparency
            line.Visible = true
            table.insert(drawnObjects, {Object = line, Pool = "Lines"})
        end
    end
end

local function DrawBox(parts, distance, drawnObjects)
    if not Config.Box.Enabled then return end
    
    local bounds = GetCharacterBounds(parts)
    if not bounds then return end
    
    local size = bounds.Max - bounds.Min
    local corners = {
        bounds.Min,
        bounds.Min + Vector3.new(size.X, 0, 0),
        bounds.Min + Vector3.new(size.X, 0, size.Z),
        bounds.Min + Vector3.new(0, 0, size.Z),
        bounds.Max,
        bounds.Max - Vector3.new(size.X, 0, 0),
        bounds.Max - Vector3.new(size.X, 0, size.Z),
        bounds.Max - Vector3.new(0, 0, size.Z),
    }
    
    local screenCorners = {}
    for _, corner in ipairs(corners) do
        local pos, vis = WorldToScreen(corner)
        if not vis then return end
        table.insert(screenCorners, pos)
    end
    
    -- Calculate 2D bounding box
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    
    for _, corner in ipairs(screenCorners) do
        minX = math.min(minX, corner.X)
        minY = math.min(minY, corner.Y)
        maxX = math.max(maxX, corner.X)
        maxY = math.max(maxY, corner.Y)
    end
    
    local boxCorners = {
        Vector2.new(minX, minY),
        Vector2.new(maxX, minY),
        Vector2.new(maxX, maxY),
        Vector2.new(minX, maxY),
    }
    
    local color = Config.Rainbow.Enabled and GetRainbowColor() or Config.Box.Color
    local transparency = Config.Box.Transparency
    
    if Config.FadeWithDistance then
        local fadeFactor = 1 - math.clamp(distance / Config.MaxDistance, 0, 1)
        transparency = transparency * fadeFactor
    end
    
    -- Draw box lines
    for i = 1, 4 do
        local line = CreateDrawing("Line", "Lines")
        line.From = boxCorners[i]
        line.To = boxCorners[i % 4 + 1]
        line.Color = color
        line.Thickness = Config.Box.Thickness
        line.Transparency = transparency
        line.Visible = true
        table.insert(drawnObjects, {Object = line, Pool = "Lines"})
    end
    
    -- Draw filled box
    if Config.Box.Filled then
        local quad = CreateDrawing("Quad", "Quads")
        quad.PointA = boxCorners[1]
        quad.PointB = boxCorners[2]
        quad.PointC = boxCorners[3]
        quad.PointD = boxCorners[4]
        quad.Color = color
        quad.Transparency = Config.Box.FilledTransparency
        quad.Filled = true
        quad.Visible = true
        table.insert(drawnObjects, {Object = quad, Pool = "Quads"})
    end
    
    return boxCorners
end

local function DrawHealthBar(parts, boxCorners, humanoid, drawnObjects)
    if not Config.HealthBar.Enabled or not humanoid then return end
    if not boxCorners then return end
    
    local healthPercent = humanoid.Health / humanoid.MaxHealth
    local barHeight = boxCorners[3].Y - boxCorners[1].Y
    local barX = boxCorners[1].X - 7
    
    -- Background
    local bgLine = CreateDrawing("Line", "Lines")
    bgLine.From = Vector2.new(barX, boxCorners[1].Y)
    bgLine.To = Vector2.new(barX, boxCorners[3].Y)
    bgLine.Color = Color3.fromRGB(0, 0, 0)
    bgLine.Thickness = Config.HealthBar.Width + 2
    bgLine.Transparency = 0.8
    bgLine.Visible = true
    table.insert(drawnObjects, {Object = bgLine, Pool = "Lines"})
    
    -- Health bar
    local healthLine = CreateDrawing("Line", "Lines")
    local healthBarHeight = barHeight * healthPercent
    healthLine.From = Vector2.new(barX, boxCorners[3].Y)
    healthLine.To = Vector2.new(barX, boxCorners[3].Y - healthBarHeight)
    healthLine.Color = Config.HealthBar.GradientEnabled and GetHealthColor(healthPercent * 100) or Color3.fromRGB(0, 255, 0)
    healthLine.Thickness = Config.HealthBar.Width
    healthLine.Transparency = 1
    healthLine.Visible = true
    table.insert(drawnObjects, {Object = healthLine, Pool = "Lines"})
end

local function DrawTracers(root, distance, drawnObjects)
    if not Config.Tracers.Enabled then return end
    
    local pos, vis = WorldToScreen(root.Position)
    if not vis then return end
    
    local screenSize = Camera.ViewportSize
    local origin
    
    if Config.Tracers.Origin == "Top" then
        origin = Vector2.new(screenSize.X / 2, 0)
    elseif Config.Tracers.Origin == "Middle" then
        origin = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
    else
        origin = Vector2.new(screenSize.X / 2, screenSize.Y)
    end
    
    local color = Config.Rainbow.Enabled and GetRainbowColor() or Config.Tracers.Color
    local transparency = Config.Tracers.Transparency
    
    if Config.FadeWithDistance then
        local fadeFactor = 1 - math.clamp(distance / Config.MaxDistance, 0, 1)
        transparency = transparency * fadeFactor
    end
    
    local line = CreateDrawing("Line", "Lines")
    line.From = origin
    line.To = pos
    line.Color = color
    line.Thickness = Config.Tracers.Thickness
    line.Transparency = transparency
    line.Visible = true
    table.insert(drawnObjects, {Object = line, Pool = "Lines"})
end

local function DrawViewAngle(root, drawnObjects)
    if not Config.ViewAngle.Enabled then return end
    
    local lookVector = root.CFrame.LookVector * Config.ViewAngle.Length
    local endPos = root.Position + lookVector
    
    local pos1, vis1 = WorldToScreen(root.Position)
    local pos2, vis2 = WorldToScreen(endPos)
    
    if vis1 and vis2 then
        local line = CreateDrawing("Line", "Lines")
        line.From = pos1
        line.To = pos2
        line.Color = Config.ViewAngle.Color
        line.Thickness = Config.ViewAngle.Thickness
        line.Transparency = 1
        line.Visible = true
        table.insert(drawnObjects, {Object = line, Pool = "Lines"})
    end
end

local function DrawInformation(player, parts, distance, humanoid, drawnObjects)
    local head = parts.Head
    local headTop = head.Position + Vector3.new(0, head.Size.Y / 2, 0)
    local headPos, vis = WorldToScreen(headTop)
    
    if not vis then return end
    
    local textSize = Config.Text.Size
    if Config.Text.ScaleWithDistance then
        local scaleFactor = math.clamp(1 - (distance / Config.MaxDistance), 0.4, 1)
        textSize = math.floor(10 + (20 - 10) * scaleFactor)
    end
    
    local yOffset = 5
    
    -- Name
    if Config.Text.Name.Enabled then
        local text = CreateDrawing("Text", "Texts")
        text.Text = player.Name
        text.Position = Vector2.new(headPos.X, headPos.Y - yOffset)
        text.Color = player.TeamColor and player.TeamColor.Color or Config.Text.Name.Color
        text.Size = textSize
        text.Outline = Config.Text.Outline
        text.Font = Config.Text.Font
        text.Transparency = 1
        text.Visible = true
        table.insert(drawnObjects, {Object = text, Pool = "Texts"})
        yOffset = yOffset + textSize + 2
    end
    
    -- Distance
    if Config.Text.Distance.Enabled then
        local text = CreateDrawing("Text", "Texts")
        text.Text = string.format("[%dm]", math.floor(distance))
        text.Position = Vector2.new(headPos.X, headPos.Y - yOffset)
        text.Color = Config.Text.Distance.Color
        text.Size = textSize - 2
        text.Outline = Config.Text.Outline
        text.Font = Config.Text.Font
        text.Transparency = 1
        text.Visible = true
        table.insert(drawnObjects, {Object = text, Pool = "Texts"})
        yOffset = yOffset + textSize
    end
    
    -- Health
    if Config.Text.Health.Enabled and humanoid then
        local healthPercent = math.floor((humanoid.Health / humanoid.MaxHealth) * 100)
        local text = CreateDrawing("Text", "Texts")
        text.Text = string.format("%d HP", math.floor(humanoid.Health))
        text.Position = Vector2.new(headPos.X, headPos.Y - yOffset)
        text.Color = GetHealthColor(healthPercent)
        text.Size = textSize - 2
        text.Outline = Config.Text.Outline
        text.Font = Config.Text.Font
        text.Transparency = 1
        text.Visible = true
        table.insert(drawnObjects, {Object = text, Pool = "Texts"})
        yOffset = yOffset + textSize
    end
    
    -- Weapon
    if Config.Text.Weapon.Enabled then
        local tool = player.Character:FindFirstChildOfClass("Tool")
        if tool then
            local text = CreateDrawing("Text", "Texts")
            text.Text = tool.Name
            text.Position = Vector2.new(headPos.X, headPos.Y - yOffset)
            text.Color = Config.Text.Weapon.Color
            text.Size = textSize - 2
            text.Outline = Config.Text.Outline
            text.Font = Config.Text.Font
            text.Transparency = 1
            text.Visible = true
            table.insert(drawnObjects, {Object = text, Pool = "Texts"})
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
--  MAIN UPDATE LOOP
-- ═══════════════════════════════════════════════════════════════

local function UpdateESP()
    if not State.Enabled then return end
    
    -- Frame rate limiting
    local currentTime = tick()
    if currentTime - State.LastUpdate < (1 / Config.UpdateRate) then
        return
    end
    State.LastUpdate = currentTime
    State.FrameCount = State.FrameCount + 1
    
    -- Update rainbow
    if Config.Rainbow.Enabled then
        State.RainbowHue = (State.RainbowHue + (0.01 / Config.Rainbow.Speed)) % 1
    end
    
    -- Return previous objects to pool
    for _, playerData in pairs(ESPData) do
        if playerData.Objects then
            for _, data in ipairs(playerData.Objects) do
                ReturnToPool(data.Pool, data.Object)
            end
        end
    end
    ESPData = {}
    
    -- Draw new frame
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if not character then continue end
        
        local parts = GetCharacterParts(character)
        if not parts then continue end
        
        local distance = (parts.Root.Position - Camera.CFrame.Position).Magnitude
        
        if not ShouldShowPlayer(player, distance) then continue end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local drawnObjects = {}
        
        -- Draw all ESP elements
        DrawSkeleton(parts, distance, drawnObjects)
        local boxCorners = DrawBox(parts, distance, drawnObjects)
        DrawHealthBar(parts, boxCorners, humanoid, drawnObjects)
        DrawTracers(parts.Root, distance, drawnObjects)
        DrawViewAngle(parts.Root, drawnObjects)
        DrawInformation(player, parts, distance, humanoid, drawnObjects)
        
        ESPData[player] = {
            Objects = drawnObjects,
            Distance = distance,
        }
    end
end

-- ═══════════════════════════════════════════════════════════════
--  INITIALIZATION
-- ═══════════════════════════════════════════════════════════════

local renderConnection = RunService.RenderStepped:Connect(UpdateESP)

-- Toggle hotkey
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Config.ToggleKey then
        State.Enabled = not State.Enabled
        if not State.Enabled then
            -- Clear all ESP when disabled
            for _, playerData in pairs(ESPData) do
                if playerData.Objects then
                    for _, data in ipairs(playerData.Objects) do
                        ReturnToPool(data.Pool, data.Object)
                    end
                end
            end
            ESPData = {}
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
--  GUI INTERFACE
-- ═══════════════════════════════════════════════════════════════

local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)

if success and Rayfield then
    local Window = Rayfield:CreateWindow({
        Name = "🎯 Premium ESP v4.0",
        LoadingTitle = "Loading ESP System",
        LoadingSubtitle = "Polished Edition",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "PremiumESP",
            FileName = "Config"
        },
    })
    
    -- ═══════════════════════════════════════════════════════════
    --  TABS
    -- ═══════════════════════════════════════════════════════════
    
    local VisualsTab = Window:CreateTab("👁️ Visuals", 4483362458)
    local FiltersTab = Window:CreateTab("🔍 Filters", 4483362458)
    local ColorsTab = Window:CreateTab("🎨 Colors", 4483362458)
    local SettingsTab = Window:CreateTab("⚙️ Settings", 4483362458)
    
    -- ═══════════════════════════════════════════════════════════
    --  VISUALS TAB
    -- ═══════════════════════════════════════════════════════════
    
    local SkeletonSection = VisualsTab:CreateSection("Skeleton ESP")
    
    VisualsTab:CreateToggle({
        Name = "Enable Skeleton",
        CurrentValue = Config.Skeleton.Enabled,
        Callback = function(value)
            Config.Skeleton.Enabled = value
        end,
    })
    
    VisualsTab:CreateSlider({
        Name = "Skeleton Thickness",
        Range = {1, 6},
        Increment = 0.5,
        CurrentValue = Config.Skeleton.Thickness,
        Callback = function(value)
            Config.Skeleton.Thickness = value
        end,
    })
    
    VisualsTab:CreateSlider({
        Name = "Skeleton Transparency",
        Range = {0, 1},
        Increment = 0.05,
        CurrentValue = Config.Skeleton.Transparency,
        Callback = function(value)
            Config.Skeleton.Transparency = value
        end,
    })
    
    local BoxSection = VisualsTab:CreateSection("Box ESP")
    
    VisualsTab:CreateToggle({
        Name = "Enable Box",
        CurrentValue = Config.Box.Enabled,
        Callback = function(value)
            Config.Box.Enabled = value
        end,
    })
    
    VisualsTab:CreateToggle({
        Name = "Filled Box",
        CurrentValue = Config.Box.Filled,
        Callback = function(value)
            Config.Box.Filled = value
        end,
    })
    
    VisualsTab:CreateSlider({
        Name = "Box Thickness",
        Range = {1, 6},
        Increment = 0.5,
        CurrentValue = Config.Box.Thickness,
        Callback = function(value)
            Config.Box.Thickness = value
        end,
    })
    
    local HealthSection = VisualsTab:CreateSection("Health Bar")
    
    VisualsTab:CreateToggle({
        Name = "Enable Health Bar",
        CurrentValue = Config.HealthBar.Enabled,
        Callback = function(value)
            Config.HealthBar.Enabled = value
        end,
    })
    
    VisualsTab:CreateToggle({
        Name = "Health Gradient",
        CurrentValue = Config.HealthBar.GradientEnabled,
        Callback = function(value)
            Config.HealthBar.GradientEnabled = value
        end,
    })
    
    VisualsTab:CreateSlider({
        Name = "Health Bar Width",
        Range = {2, 8},
        Increment = 1,
        CurrentValue = Config.HealthBar.Width,
        Callback = function(value)
            Config.HealthBar.Width = value
        end,
    })
    
    local TracersSection = VisualsTab:CreateSection("Tracers")
    
    VisualsTab:CreateToggle({
        Name = "Enable Tracers",
        CurrentValue = Config.Tracers.Enabled,
        Callback = function(value)
            Config.Tracers.Enabled = value
        end,
    })
    
    VisualsTab:CreateDropdown({
        Name = "Tracer Origin",
        Options = {"Top", "Middle", "Bottom"},
        CurrentOption = Config.Tracers.Origin,
        Callback = function(value)
            Config.Tracers.Origin = value
        end,
    })
    
    VisualsTab:CreateSlider({
        Name = "Tracer Thickness",
        Range = {0.5, 5},
        Increment = 0.5,
        CurrentValue = Config.Tracers.Thickness,
        Callback = function(value)
            Config.Tracers.Thickness = value
        end,
    })
    
    local InfoSection = VisualsTab:CreateSection("Information Display")
    
    VisualsTab:CreateToggle({
        Name = "Show Names",
        CurrentValue = Config.Text.Name.Enabled,
        Callback = function(value)
            Config.Text.Name.Enabled = value
        end,
    })
    
    VisualsTab:CreateToggle({
        Name = "Show Distance",
        CurrentValue = Config.Text.Distance.Enabled,
        Callback = function(value)
            Config.Text.Distance.Enabled = value
        end,
    })
    
    VisualsTab:CreateToggle({
        Name = "Show Health",
        CurrentValue = Config.Text.Health.Enabled,
        Callback = function(value)
            Config.Text.Health.Enabled = value
        end,
    })
    
    VisualsTab:CreateToggle({
        Name = "Show Weapon",
        CurrentValue = Config.Text.Weapon.Enabled,
        Callback = function(value)
            Config.Text.Weapon.Enabled = value
        end,
    })
    
    VisualsTab:CreateToggle({
        Name = "Scale Text with Distance",
        CurrentValue = Config.Text.ScaleWithDistance,
        Callback = function(value)
            Config.Text.ScaleWithDistance = value
        end,
    })
    
    local ViewAngleSection = VisualsTab:CreateSection("View Angle")
    
    VisualsTab:CreateToggle({
        Name = "Enable View Angle",
        CurrentValue = Config.ViewAngle.Enabled,
        Callback = function(value)
            Config.ViewAngle.Enabled = value
        end,
    })
    
    VisualsTab:CreateSlider({
        Name = "View Angle Length",
        Range = {3, 15},
        Increment = 1,
        CurrentValue = Config.ViewAngle.Length,
        Callback = function(value)
            Config.ViewAngle.Length = value
        end,
    })
    
    -- ═══════════════════════════════════════════════════════════
    --  FILTERS TAB
    -- ═══════════════════════════════════════════════════════════
    
    local FilterSection = FiltersTab:CreateSection("Target Filters")
    
    FiltersTab:CreateToggle({
        Name = "Team Check",
        CurrentValue = Config.TeamCheck,
        Callback = function(value)
            Config.TeamCheck = value
        end,
    })
    
    FiltersTab:CreateToggle({
        Name = "Health Check (Hide Dead)",
        CurrentValue = Config.HealthCheck,
        Callback = function(value)
            Config.HealthCheck = value
        end,
    })
    
    FiltersTab:CreateToggle({
        Name = "Visibility Check",
        CurrentValue = Config.VisibilityCheck,
        Callback = function(value)
            Config.VisibilityCheck = value
        end,
    })
    
    local DistanceSection = FiltersTab:CreateSection("Distance Filters")
    
    FiltersTab:CreateSlider({
        Name = "Max Distance (studs)",
        Range = {100, 3000},
        Increment = 50,
        CurrentValue = Config.MaxDistance,
        Callback = function(value)
            Config.MaxDistance = value
        end,
    })
    
    FiltersTab:CreateSlider({
        Name = "Min Distance (studs)",
        Range = {0, 500},
        Increment = 10,
        CurrentValue = Config.MinDistance,
        Callback = function(value)
            Config.MinDistance = value
        end,
    })
    
    -- ═══════════════════════════════════════════════════════════
    --  COLORS TAB
    -- ═══════════════════════════════════════════════════════════
    
    local RainbowSection = ColorsTab:CreateSection("Rainbow Mode")
    
    ColorsTab:CreateToggle({
        Name = "Enable Rainbow",
        CurrentValue = Config.Rainbow.Enabled,
        Callback = function(value)
            Config.Rainbow.Enabled = value
        end,
    })
    
    ColorsTab:CreateSlider({
        Name = "Rainbow Speed",
        Range = {1, 10},
        Increment = 1,
        CurrentValue = Config.Rainbow.Speed,
        Callback = function(value)
            Config.Rainbow.Speed = value
        end,
    })
    
    local ColorSection = ColorsTab:CreateSection("Custom Colors")
    
    ColorsTab:CreateColorPicker({
        Name = "Skeleton Color",
        Color = Config.Skeleton.Color,
        Callback = function(value)
            Config.Skeleton.Color = value
        end,
    })
    
    ColorsTab:CreateColorPicker({
        Name = "Box Color",
        Color = Config.Box.Color,
        Callback = function(value)
            Config.Box.Color = value
        end,
    })
    
    ColorsTab:CreateColorPicker({
        Name = "Tracer Color",
        Color = Config.Tracers.Color,
        Callback = function(value)
            Config.Tracers.Color = value
        end,
    })
    
    ColorsTab:CreateColorPicker({
        Name = "View Angle Color",
        Color = Config.ViewAngle.Color,
        Callback = function(value)
            Config.ViewAngle.Color = value
        end,
    })
    
    -- ═══════════════════════════════════════════════════════════
    --  SETTINGS TAB
    -- ═══════════════════════════════════════════════════════════
    
    local PerformanceSection = SettingsTab:CreateSection("Performance")
    
    SettingsTab:CreateSlider({
        Name = "Update Rate (FPS)",
        Range = {30, 120},
        Increment = 10,
        CurrentValue = Config.UpdateRate,
        Callback = function(value)
            Config.UpdateRate = value
        end,
    })
    
    SettingsTab:CreateToggle({
        Name = "Fade with Distance",
        CurrentValue = Config.FadeWithDistance,
        Callback = function(value)
            Config.FadeWithDistance = value
        end,
    })
    
    local TextSection = SettingsTab:CreateSection("Text Settings")
    
    SettingsTab:CreateSlider({
        Name = "Base Text Size",
        Range = {10, 24},
        Increment = 1,
        CurrentValue = Config.Text.Size,
        Callback = function(value)
            Config.Text.Size = value
        end,
    })
    
    SettingsTab:CreateToggle({
        Name = "Text Outline",
        CurrentValue = Config.Text.Outline,
        Callback = function(value)
            Config.Text.Outline = value
        end,
    })
    
    SettingsTab:CreateDropdown({
        Name = "Text Font",
        Options = {"UI", "System", "Plex", "Monospace"},
        CurrentOption = {"UI", "System", "Plex", "Monospace"}[Config.Text.Font] or "Plex",
        Callback = function(value)
            local fonts = {UI = 0, System = 1, Plex = 2, Monospace = 3}
            Config.Text.Font = fonts[value] or 2
        end,
    })
    
    local ControlSection = SettingsTab:CreateSection("Controls")
    
    SettingsTab:CreateKeybind({
        Name = "Toggle ESP",
        CurrentKeybind = Config.ToggleKey.Name,
        HoldToInteract = false,
        Callback = function(key)
            Config.ToggleKey = key
        end,
    })
    
    SettingsTab:CreateButton({
        Name = "Enable ESP",
        Callback = function()
            State.Enabled = true
        end,
    })
    
    SettingsTab:CreateButton({
        Name = "Disable ESP",
        Callback = function()
            State.Enabled = false
            for _, playerData in pairs(ESPData) do
                if playerData.Objects then
                    for _, data in ipairs(playerData.Objects) do
                        ReturnToPool(data.Pool, data.Object)
                    end
                end
            end
            ESPData = {}
        end,
    })
    
    Rayfield:LoadConfiguration()
end

-- ═══════════════════════════════════════════════════════════════
--  CLEANUP
-- ═══════════════════════════════════════════════════════════════

game:GetService("Players").PlayerRemoving:Connect(function(player)
    if ESPData[player] then
        if ESPData[player].Objects then
            for _, data in ipairs(ESPData[player].Objects) do
                ReturnToPool(data.Pool, data.Object)
            end
        end
        ESPData[player] = nil
    end
end)

print("═══════════════════════════════════════════════════════════")
print("  Premium ESP v4.0 - Loaded Successfully")
print("  Press", Config.ToggleKey.Name, "to toggle ESP")
print("═══════════════════════════════════════════════════════════")