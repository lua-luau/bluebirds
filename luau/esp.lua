-- Prevent duplicate ESP instance
if getgenv().ESP then
    return getgenv().ESP
end

local ESP = {}
getgenv().ESP = ESP

-- Default Settings
ESP.Settings = {
    ShowBoxes = true,
    ShowTracers = true,
    ShowNames = true,
    ShowTeammates = false,
    TextSize = 16,
    BoxThickness = 2,
    TracerThickness = 1.5,
    TracerOrigin = "Bottom", -- "Bottom" or "Center"
    BaseTransparency = 0.2,
    MinTransparency = 0.6,
    MaxDistance = 1000,
    TeamColor = true
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local espObjects = {}

-- Utility
local function worldToScreen(position)
    local screenPos, visible = Camera:WorldToViewportPoint(position)
    return Vector2.new(screenPos.X, screenPos.Y), visible, screenPos.Z
end

local function calculateTransparency(distance)
    local max = ESP.Settings.MaxDistance
    local alpha = 1 - math.clamp(distance / max, 0, 1)
    return math.clamp(ESP.Settings.BaseTransparency + (alpha * (ESP.Settings.MinTransparency - ESP.Settings.BaseTransparency)), 0, 1)
end

local function getBoundingBox(character)
    local parts = {}
    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and part.Transparency < 1 then
            table.insert(parts, part)
        end
    end
    if #parts == 0 then return end
    local min, max = parts[1].Position, parts[1].Position
    for _, p in ipairs(parts) do
        local pos = p.Position
        min = Vector3.new(math.min(min.X, pos.X), math.min(min.Y, pos.Y), math.min(min.Z, pos.Z))
        max = Vector3.new(math.max(max.X, pos.X), math.max(max.Y, pos.Y), math.max(max.Z, pos.Z))
    end
    return (min + max) / 2, max - min
end

local function createESP(player)
    if espObjects[player] or player == LocalPlayer then return end

    local box = Drawing.new("Square")
    box.Thickness = ESP.Settings.BoxThickness
    box.Filled = false
    box.Visible = false

    local tracer = Drawing.new("Line")
    tracer.Thickness = ESP.Settings.TracerThickness
    tracer.Visible = false

    local name = Drawing.new("Text")
    name.Size = ESP.Settings.TextSize
    name.Center = true
    name.Outline = true
    name.Visible = false

    espObjects[player] = {Box = box, Tracer = tracer, Name = name}

    player.AncestryChanged:Connect(function(_, parent)
        if not parent then
            box:Remove()
            tracer:Remove()
            name:Remove()
            espObjects[player] = nil
        end
    end)
end

local function updateESP()
    for player, draw in pairs(espObjects) do
        local character = player.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            draw.Box.Visible = false
            draw.Tracer.Visible = false
            draw.Name.Visible = false
            continue
        end
        if not ESP.Settings.ShowTeammates and player.Team == LocalPlayer.Team then
            draw.Box.Visible = false
            draw.Tracer.Visible = false
            draw.Name.Visible = false
            continue
        end

        local center, size = getBoundingBox(character)
        if not center or not size then
            draw.Box.Visible = false
            draw.Tracer.Visible = false
            draw.Name.Visible = false
            continue
        end

        local topLeft3D = center + Vector3.new(-size.X/2, size.Y/2, 0)
        local bottomRight3D = center + Vector3.new(size.X/2, -size.Y/2, 0)

        local topLeft, vis1, z1 = worldToScreen(topLeft3D)
        local bottomRight, vis2, z2 = worldToScreen(bottomRight3D)
        local rootScreen, visible, z = worldToScreen(character.HumanoidRootPart.Position)

        if visible and vis1 and vis2 then
            local boxSize = bottomRight - topLeft
            local teamColor = (ESP.Settings.TeamColor and player.Team and player.Team.TeamColor.Color) or Color3.fromRGB(255,255,255)
            local alpha = calculateTransparency((Camera.CFrame.Position - character.HumanoidRootPart.Position).Magnitude)

            draw.Box.Position = topLeft
            draw.Box.Size = boxSize
            draw.Box.Color = teamColor
            draw.Box.Transparency = alpha
            draw.Box.Visible = ESP.Settings.ShowBoxes

            draw.Tracer.From = ESP.Settings.TracerOrigin == "Center" and Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2) or Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
            draw.Tracer.To = rootScreen
            draw.Tracer.Color = teamColor
            draw.Tracer.Transparency = alpha
            draw.Tracer.Visible = ESP.Settings.ShowTracers

            draw.Name.Text = player.Name
            draw.Name.Position = Vector2.new(topLeft.X + boxSize.X/2, topLeft.Y - ESP.Settings.TextSize - 2)
            draw.Name.Color = teamColor
            draw.Name.Transparency = alpha
            draw.Name.Visible = ESP.Settings.ShowNames
        else
            draw.Box.Visible = false
            draw.Tracer.Visible = false
            draw.Name.Visible = false
        end
    end
end

-- Runtime
for _, p in ipairs(Players:GetPlayers()) do
    createESP(p)
end
Players.PlayerAdded:Connect(createESP)

RunService.RenderStepped:Connect(updateESP)

function ESP:Unload()
    for _, obj in pairs(espObjects) do
        for _, d in pairs(obj) do
            d:Remove()
        end
    end
    espObjects = {}
    getgenv().ESP = nil
end

return ESP
