-- Prevent duplicate aimbot instance
if getgenv().Aimbot then
    return getgenv().Aimbot
end

local Aimbot = {}
getgenv().Aimbot = Aimbot

-- Settings
Aimbot.Settings = {
    AimFOV = 35,
    AimSmoothing = 0.15, -- 0 = snap, 1 = no movement
    EnableFOVSync = true,
    ShowFOVCircle = true,
    TeamCheck = false,
    UseLineOfSight = true,
    HealthCheck = true,
    TargetPart = "Head",
    LOSParts = {"Head", "HumanoidRootPart"},
    ScoreWeights = { FOV = 0.6, Distance = 0.4 },
    CustomCrosshair = Vector2.new(0.5, 0.5) -- normalized screen position
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local player = Players.LocalPlayer

-- Remove any existing FOV circle
if getgenv().AimbotFOVCircle then
    getgenv().AimbotFOVCircle:Remove()
    getgenv().AimbotFOVCircle = nil
end

-- Create Drawing Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Color = Color3.fromRGB(0, 255, 0)
fovCircle.Thickness = 2
fovCircle.Filled = false
fovCircle.Transparency = 0.4
fovCircle.Visible = Aimbot.Settings.ShowFOVCircle
getgenv().AimbotFOVCircle = fovCircle

local cachedPlayers, lastPlayerCache = {}, 0
local function refreshPlayerCache()
    if tick() - lastPlayerCache > 0.25 then
        cachedPlayers = Players:GetPlayers()
        lastPlayerCache = tick()
    end
end

local function checkLineOfSight(char)
    for _, partName in ipairs(Aimbot.Settings.LOSParts) do
        local part = char:FindFirstChild(partName)
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if part and root then
            local dir = (part.Position - root.Position)
            local rayParams = RaycastParams.new()
            rayParams.FilterType = Enum.RaycastFilterType.Blacklist
            rayParams.FilterDescendantsInstances = {char, player.Character}
            local result = workspace:Raycast(root.Position, dir, rayParams)
            if result and not result.Instance:IsDescendantOf(char) then
                return false
            end
        end
    end
    return true
end

local function getCustomCrosshair()
    local viewport = Camera.ViewportSize
    local scale = Aimbot.Settings.CustomCrosshair
    if typeof(scale) ~= "Vector2" or scale.X < 0 or scale.X > 1 or scale.Y < 0 or scale.Y > 1 then
        scale = Vector2.new(0.5, 0.5)
    end
    return Vector2.new(viewport.X * scale.X, viewport.Y * scale.Y)
end

local function getClosestTarget()
    refreshPlayerCache()
    local best, bestScore = nil, -math.huge
    local camPos = Camera.CFrame.Position
    local screenPoint = getCustomCrosshair()
    local ray = Camera:ScreenPointToRay(screenPoint.X, screenPoint.Y)
    local aimOrigin = ray.Origin
    local aimDirection = ray.Direction.Unit

    for _, otherPlayer in ipairs(cachedPlayers) do
        if otherPlayer ~= player and otherPlayer.Character then
            local targetPart = otherPlayer.Character:FindFirstChild(Aimbot.Settings.TargetPart)
            local humanoid = otherPlayer.Character:FindFirstChildOfClass("Humanoid")
            if targetPart and (not Aimbot.Settings.HealthCheck or (humanoid and humanoid.Health > 0)) then
                if not Aimbot.Settings.TeamCheck or otherPlayer.Team ~= player.Team then
                    local toTarget = (targetPart.Position - aimOrigin).Unit
                    local angle = math.deg(math.acos(math.clamp(aimDirection:Dot(toTarget), -1, 1)))
                    if angle <= Aimbot.Settings.AimFOV then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                        if onScreen then
                            local dist = (targetPart.Position - camPos).Magnitude
                            local losOK = not Aimbot.Settings.UseLineOfSight or checkLineOfSight(otherPlayer.Character)
                            if losOK then
                                local score =
                                    ((1 - (angle / Aimbot.Settings.AimFOV)) * Aimbot.Settings.ScoreWeights.FOV) +
                                    ((1 / dist) * Aimbot.Settings.ScoreWeights.Distance)
                                if score > bestScore then
                                    bestScore = score
                                    best = {
                                        Part = targetPart,
                                        Position = targetPart.Position,
                                        Angle = angle,
                                        Distance = dist,
                                        ScreenPos = screenPos
                                    }
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

local function updateFOVCircle()
    if not Aimbot.Settings.ShowFOVCircle then
        fovCircle.Visible = false
        return
    end
    local camFOV = Camera.FieldOfView
    local screenHeight = Camera.ViewportSize.Y
    local scale = math.tan(math.rad(Aimbot.Settings.AimFOV / 2)) / math.tan(math.rad(camFOV / 2))
    fovCircle.Radius = (screenHeight / 2) * scale
    fovCircle.Position = getCustomCrosshair()
    fovCircle.Visible = true
end

-- Public Start Function
function Aimbot.Start()
    if Aimbot._conn then Aimbot._conn:Disconnect() end

    Aimbot._conn = RunService.RenderStepped:Connect(function()
        if not player.Character or not Camera then return end

        updateFOVCircle()

        local targetData = getClosestTarget()
        if targetData then
            local screenPoint = getCustomCrosshair()
            local ray = Camera:ScreenPointToRay(screenPoint.X, screenPoint.Y)
            local aimOrigin = ray.Origin
            local assistDir = (targetData.Position - aimOrigin).Unit
            local currentCFrame = Camera.CFrame
            local targetCFrame = CFrame.new(currentCFrame.Position, currentCFrame.Position + assistDir)
            local smoothing = math.clamp(Aimbot.Settings.AimSmoothing, 0, 1)
            Camera.CFrame = currentCFrame:Lerp(targetCFrame, 1 - smoothing)
        end
    end)
end

function Aimbot.Stop()
    if Aimbot._conn then
        Aimbot._conn:Disconnect()
        Aimbot._conn = nil
    end
    if getgenv().AimbotFOVCircle then
        getgenv().AimbotFOVCircle:Remove()
        getgenv().AimbotFOVCircle = nil
    end
end

return Aimbot