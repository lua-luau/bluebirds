-- ESP.lua
-- reloadable, externally-controlled ESP module with live-update settings

---------------------------------------------------------------------
--  ⇨  GLOBAL SHARED STATE (reload-safe)
---------------------------------------------------------------------
local Shared = (getgenv and getgenv().__CustomESP) or (_G.__CustomESP)

if not Shared then
    Shared = {}
    if getgenv then
        getgenv().__CustomESP = Shared
    else
        _G.__CustomESP = Shared
    end
end

-- Clean up prior run (hot-reload support)
if Shared.runningConnection then Shared.runningConnection:Disconnect() end
if Shared.espObjects then
    for _, esp in pairs(Shared.espObjects) do
        esp.Box:Remove()
        esp.Name:Remove()
        esp.Tracer:Remove()
    end
end
Shared.runningConnection = nil
Shared.connections     = {}
Shared.espObjects      = {}

---------------------------------------------------------------------
--  ⇨  SERVICES & LOCALS
---------------------------------------------------------------------
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera     = workspace.CurrentCamera
local LocalPlayer= Players.LocalPlayer

---------------------------------------------------------------------
--  ⇨  MODULE
---------------------------------------------------------------------
local ESP = {}

---------------------------------------------------------------------
--  SETTINGS  (defaults)
---------------------------------------------------------------------
ESP.Settings = {
    ShowTeammates    = true,
    ShowNames        = true,      -- NEW  ← enable/disable player name
    BoxThickness     = 2,
    TextSize         = 10,
    TracerThickness  = 1,
    TracerOrigin     = "Bottom",  -- "Center" | "Bottom"
    MaxFadeDistance  = 3500,
    MinTransparency  = 0.3,
    BaseTransparency = 0.8,
}

--- Live-update helper ------------------------------------------------
local function applySettingToESPObjects(key, value)
    if key == "BoxThickness" then
        for _, esp in pairs(Shared.espObjects) do esp.Box.Thickness     = value end
    elseif key == "TracerThickness" then
        for _, esp in pairs(Shared.espObjects) do esp.Tracer.Thickness = value end
    elseif key == "TextSize" then
        for _, esp in pairs(Shared.espObjects) do esp.Name.Size        = value end
    end
end

--- Public runtime-update function -----------------------------------
function ESP.UpdateSettings(tbl)
    for k, v in pairs(tbl) do
        if ESP.Settings[k] ~= nil then
            ESP.Settings[k] = v
            applySettingToESPObjects(k, v)
        end
    end
end

---------------------------------------------------------------------
--  INTERNAL HELPERS
---------------------------------------------------------------------
local function clearESP(player)
    local esp = Shared.espObjects[player]
    if not esp then return end
    esp.Box:Remove(); esp.Name:Remove(); esp.Tracer:Remove()
    Shared.espObjects[player] = nil
end

local function createESP(player)
    if player == LocalPlayer or Shared.espObjects[player] then return end

    local box = Drawing.new("Square")
    box.Filled     = false

    local name = Drawing.new("Text")
    name.Center   = true
    name.Outline  = true
    name.Font     = Drawing.Fonts.UI

    local tracer = Drawing.new("Line")

    Shared.espObjects[player] = {Box = box, Name = name, Tracer = tracer}

    -- immediate application of current adjustable properties
    applySettingToESPObjects("BoxThickness",    ESP.Settings.BoxThickness)
    applySettingToESPObjects("TracerThickness", ESP.Settings.TracerThickness)
    applySettingToESPObjects("TextSize",        ESP.Settings.TextSize)

    table.insert(Shared.connections, player.AncestryChanged:Connect(function(_, parent)
        if not parent then clearESP(player) end
    end))
end

---------------------------------------------------------------------
--  MAIN UPDATE LOOP
---------------------------------------------------------------------
local function updateESP()
    local scrC   = Camera.ViewportSize / 2
    local scrBot = Vector2.new(scrC.X, Camera.ViewportSize.Y)
    local lChar  = LocalPlayer.Character
    local lHRP   = lChar and lChar:FindFirstChild("HumanoidRootPart")
    if not lHRP then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        createESP(player)

        local esp       = Shared.espObjects[player]
        local char      = player.Character
        local hrp       = char and char:FindFirstChild("HumanoidRootPart")
        local head      = char and char:FindFirstChild("Head")
        local humanoid  = char and char:FindFirstChildOfClass("Humanoid")

        if not (hrp and head and humanoid and humanoid.Health > 0) or
           (not ESP.Settings.ShowTeammates and player.Team == LocalPlayer.Team) then
            esp.Box.Visible, esp.Name.Visible, esp.Tracer.Visible = false, false, false
            continue
        end

        local hrpPos, on1 = Camera:WorldToViewportPoint(hrp.Position)
        local headPos,on2 = Camera:WorldToViewportPoint(head.Position)
        if not (on1 and on2 and hrpPos.Z > 0 and headPos.Z > 0) then
            esp.Box.Visible, esp.Name.Visible, esp.Tracer.Visible = false, false, false
            continue
        end

        -- sizing
        local height = math.abs(hrpPos.Y - headPos.Y) * 2.5
        local width  = height / 2
        local boxPos = Vector2.new(hrpPos.X - width / 2, hrpPos.Y - height / 2)
        local boxSize= Vector2.new(width, height)

        -- fade
        local dist   = (lHRP.Position - hrp.Position).Magnitude
        local fade   = math.clamp(dist / ESP.Settings.MaxFadeDistance, 0, 1)
        local alpha  = math.clamp(
            ESP.Settings.BaseTransparency + fade * (ESP.Settings.MinTransparency - ESP.Settings.BaseTransparency),
            0, 1)

        -- color
        local color  = (player.Team and player.Team.TeamColor.Color) or Color3.new(1,1,1)

        -- BOX
        esp.Box.Position     = boxPos
        esp.Box.Size         = boxSize
        esp.Box.Color        = color
        esp.Box.Transparency = alpha
        esp.Box.Visible      = true

        -- NAME (honours ShowNames)
        if ESP.Settings.ShowNames then
            esp.Name.Text        = player.Name
            esp.Name.Position    = Vector2.new(boxPos.X + width / 2, boxPos.Y - ESP.Settings.TextSize - 2)
            esp.Name.Color       = color
            esp.Name.Transparency= alpha
            esp.Name.Visible     = true
        else
            esp.Name.Visible     = false
        end

        -- TRACER
        local origin          = (ESP.Settings.TracerOrigin == "Bottom") and scrBot or scrC
        esp.Tracer.From       = origin
        esp.Tracer.To         = Vector2.new(hrpPos.X, hrpPos.Y)
        esp.Tracer.Color      = color
        esp.Tracer.Transparency = alpha
        esp.Tracer.Visible    = true
    end
end

---------------------------------------------------------------------
--  PUBLIC API
---------------------------------------------------------------------
function ESP.Start()
    if Shared.runningConnection then return end
    Shared.runningConnection = RunService.RenderStepped:Connect(updateESP)

    table.insert(Shared.connections, Players.PlayerAdded:Connect(createESP))
    table.insert(Shared.connections, Players.PlayerRemoving:Connect(clearESP))

    for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
end

function ESP.Stop()
    if Shared.runningConnection then Shared.runningConnection:Disconnect(); Shared.runningConnection = nil end
    for _, c in ipairs(Shared.connections) do pcall(function() c:Disconnect() end) end
    Shared.connections = {}

    for _, esp in pairs(Shared.espObjects) do
        esp.Box:Remove(); esp.Name:Remove(); esp.Tracer:Remove()
    end
    Shared.espObjects = {}
end

return ESP