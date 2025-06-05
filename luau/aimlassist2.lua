if getgenv().Aimbot then return getgenv().Aimbot end

local Aimbot = {}
getgenv().Aimbot = Aimbot

Aimbot.Settings = {
    AimFOV = 60,
    UseLineOfSight = true,
    HealthCheck = true,
    TeamCheck = false,
    TargetPart = "Head",
    LOSParts = {"Head", "HumanoidRootPart"},
    MaxPredictionTime = 0.2,
    PingFallback = 50,
    ScoreWeights = { FOV = 0.6, Distance = 0.4 },
    CustomCrosshair = Vector2.new(0.5, 0.5),
    ShowFOVCircle = true
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Optional: Draw FOV Circle
if getgenv().AimbotFOVCircle then
    getgenv().AimbotFOVCircle:Remove()
end

local fovCircle = Drawing.new("Circle")
fovCircle.Color = Color3.fromRGB(255, 0, 0)
fovCircle.Thickness = 2
fovCircle.Filled = false
fovCircle.Transparency = 0.5
fovCircle.Visible = Aimbot.Settings.ShowFOVCircle
getgenv().AimbotFOVCircle = fovCircle

local cachedPlayers, lastCache = {}, 0
local function refreshPlayers()
    if tick() - lastCache > 0.25 then
        cachedPlayers = Players:GetPlayers()
        lastCache = tick()
    end
end

local function getPredictedPosition(part)
    local vel = part:IsA("BasePart") and part.Velocity or Vector3.zero
    local t = math.clamp(Aimbot.Settings.PingFallback / 1000, 0, Aimbot.Settings.MaxPredictionTime)
    return part.Position + (vel * t)
end

local function checkLineOfSight(char)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    for _, partName in ipairs(Aimbot.Settings.LOSParts) do
        local part = char:FindFirstChild(partName)
        if part then
            local dir = root.Position - part.Position
            local rayParams = RaycastParams.new()
            rayParams.FilterType = Enum.RaycastFilterType.Blacklist
            rayParams.FilterDescendantsInstances = {char, LocalPlayer.Character}
            local result = workspace:Raycast(part.Position, dir.Unit * dir.Magnitude, rayParams)
            if result and not result.Instance:IsDescendantOf(LocalPlayer.Character) then
                return false
            end
        end
    end
    return true
end

local function getCustomCrosshair()
    local size = Camera.ViewportSize
    local scale = Aimbot.Settings.CustomCrosshair
    return Vector2.new(size.X * scale.X, size.Y * scale.Y)
end

local function getClosestTarget()
    refreshPlayers()

    local best, bestScore = nil, -math.huge
    local camPos = Camera.CFrame.Position
    local screenCenter = getCustomCrosshair()
    local ray = Camera:ScreenPointToRay(screenCenter.X, screenCenter.Y)

    for _, target in ipairs(cachedPlayers) do
        if target ~= LocalPlayer and target.Character then
            local part = target.Character:FindFirstChild(Aimbot.Settings.TargetPart)
            local humanoid = target.Character:FindFirstChildOfClass("Humanoid")

            if part and (not Aimbot.Settings.HealthCheck or (humanoid and humanoid.Health > 0)) then
                if not Aimbot.Settings.TeamCheck or target.Team ~= LocalPlayer.Team then
                    local predicted = getPredictedPosition(part)
                    local toTarget = (predicted - ray.Origin).Unit
                    local angle = math.deg(math.acos(math.clamp(ray.Direction:Dot(toTarget), -1, 1)))

                    if angle <= Aimbot.Settings.AimFOV then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(predicted)
                        if onScreen then
                            local dist = (camPos - part.Position).Magnitude
                            local losOK = not Aimbot.Settings.UseLineOfSight or checkLineOfSight(target.Character)
                            if losOK then
                                local score = ((1 - (angle / Aimbot.Settings.AimFOV)) * Aimbot.Settings.ScoreWeights.FOV)
                                    + ((1 / dist) * Aimbot.Settings.ScoreWeights.Distance)

                                if score > bestScore then
                                    bestScore = score
                                    best = predicted
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

local function updateFOV()
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

function Aimbot.Start()
    RunService.RenderStepped:Connect(function()
        if not LocalPlayer.Character or not Camera then return end

        updateFOV()

        local targetPos = getClosestTarget()
        if targetPos then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPos)
        end
    end)
end

return Aimbot