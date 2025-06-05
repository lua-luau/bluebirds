-- ESP.lua
-- Singleton-safe, reloadable, externally controlled ESP module

--// GLOBAL SINGLETON PROTECTION
if getgenv then
    getgenv().__CustomESP = getgenv().__CustomESP or {}
else
    _G.__CustomESP = _G.__CustomESP or {}
end

local Shared = getgenv and getgenv().__CustomESP or _G.__CustomESP

-- Stop previous ESP if already running
if Shared.runningConnection then
    Shared.runningConnection:Disconnect()
end

if Shared.espObjects then
    for _, esp in pairs(Shared.espObjects) do
        esp.Box:Remove()
        esp.Name:Remove()
        esp.Tracer:Remove()
    end
end

Shared.espObjects = {}
Shared.runningConnection = nil
Shared.connections = {}

--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

--// MODULE TABLE
local ESP = {}

ESP.Settings = {
    ShowTeammates = true,
    BoxThickness = 2,
    TextSize = 10,
    TracerThickness = 1,
    TracerOrigin = "Bottom", -- "Center" or "Bottom"
    MaxFadeDistance = 3500,
    MinTransparency = 0.3,
    BaseTransparency = 0.8,
}

--// INTERNAL
local function clearESP(player)
    local esp = Shared.espObjects[player]
    if esp then
        esp.Box:Remove()
        esp.Name:Remove()
        esp.Tracer:Remove()
        Shared.espObjects[player] = nil
    end
end

local function createESP(player)
    if player == LocalPlayer or Shared.espObjects[player] then return end

    local box = Drawing.new("Square")
    box.Thickness = ESP.Settings.BoxThickness
    box.Filled = false
    box.Visible = false

    local name = Drawing.new("Text")
    name.Size = ESP.Settings.TextSize
    name.Center = true
    name.Outline = true
    name.Font = Drawing.Fonts.UI
    name.Visible = false

    local tracer = Drawing.new("Line")
    tracer.Thickness = ESP.Settings.TracerThickness
    tracer.Visible = false

    Shared.espObjects[player] = {Box = box, Name = name, Tracer = tracer}

    table.insert(Shared.connections, player.AncestryChanged:Connect(function(_, parent)
        if not parent then
            clearESP(player)
        end
    end))
end

local function updateESP()
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local screenBottom = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    local localCharacter = LocalPlayer.Character
    local localHRP = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
    if not localHRP then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        createESP(player)

        local esp = Shared.espObjects[player]
        local character = player.Character
        if not character then
            esp.Box.Visible = false
            esp.Name.Visible = false
            esp.Tracer.Visible = false
            continue
        end

        local hrp = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
        local head = character:FindFirstChild("Head")
        local humanoid = character:FindFirstChildOfClass("Humanoid")

        if not hrp or not head or not humanoid or humanoid.Health <= 0 then
            esp.Box.Visible = false
            esp.Name.Visible = false
            esp.Tracer.Visible = false
            continue
        end

        if not ESP.Settings.ShowTeammates and player.Team == LocalPlayer.Team then
            esp.Box.Visible = false
            esp.Name.Visible = false
            esp.Tracer.Visible = false
            continue
        end

        local hrpPos, onScreen1 = Camera:WorldToViewportPoint(hrp.Position)
        local headPos, onScreen2 = Camera:WorldToViewportPoint(head.Position)
        if not (onScreen1 and onScreen2 and hrpPos.Z > 0 and headPos.Z > 0) then
            esp.Box.Visible = false
            esp.Name.Visible = false
            esp.Tracer.Visible = false
            continue
        end

        local height = math.abs(hrpPos.Y - headPos.Y) * 2.5
        local width = height / 2
        local boxPos = Vector2.new(hrpPos.X - width / 2, hrpPos.Y - height / 2)
        local boxSize = Vector2.new(width, height)

        local distance = (localHRP.Position - hrp.Position).Magnitude
        local fadeRatio = math.clamp(distance / ESP.Settings.MaxFadeDistance, 0, 1)
        local transparency = math.clamp(
            ESP.Settings.BaseTransparency + fadeRatio * (ESP.Settings.MinTransparency - ESP.Settings.BaseTransparency),
            0, 1
        )

        local teamColor = player.Team and player.Team.TeamColor.Color or Color3.new(1, 1, 1)

        esp.Box.Position = boxPos
        esp.Box.Size = boxSize
        esp.Box.Color = teamColor
        esp.Box.Transparency = transparency
        esp.Box.Visible = true

        esp.Name.Text = player.Name
        esp.Name.Position = Vector2.new(boxPos.X + width / 2, boxPos.Y - ESP.Settings.TextSize - 2)
        esp.Name.Color = teamColor
        esp.Name.Transparency = transparency
        esp.Name.Visible = true

        local origin = ESP.Settings.TracerOrigin == "Bottom" and screenBottom or screenCenter
        esp.Tracer.From = origin
        esp.Tracer.To = Vector2.new(hrpPos.X, hrpPos.Y)
        esp.Tracer.Color = teamColor
        esp.Tracer.Transparency = transparency
        esp.Tracer.Visible = true
    end
end

--// START
function ESP.Start()
    if Shared.runningConnection then return end
    Shared.runningConnection = RunService.RenderStepped:Connect(updateESP)

    table.insert(Shared.connections, Players.PlayerAdded:Connect(createESP))
    table.insert(Shared.connections, Players.PlayerRemoving:Connect(clearESP))

    for _, player in ipairs(Players:GetPlayers()) do
        createESP(player)
    end
end

--// STOP
function ESP.Stop()
    if Shared.runningConnection then
        Shared.runningConnection:Disconnect()
        Shared.runningConnection = nil
    end

    for _, conn in ipairs(Shared.connections) do
        pcall(function() conn:Disconnect() end)
    end
    Shared.connections = {}

    for _, esp in pairs(Shared.espObjects) do
        esp.Box:Remove()
        esp.Name:Remove()
        esp.Tracer:Remove()
    end

    Shared.espObjects = {}
end

return ESP