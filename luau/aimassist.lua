if getgenv().Aimbot then
    return getgenv().Aimbot
end

local Aimbot = {}
getgenv().Aimbot = Aimbot

-- Settings
Aimbot.Settings = {
    Enabled = true,
    AimFOV = 35,
    AimSmoothing = 0.15,
    ShowFOVCircle = true,
    TeamCheck = false,
    UseLineOfSight = true,
    HealthCheck = true,
    TargetPart = "Head",
    LOSParts = {"Head", "HumanoidRootPart"},
    FOVCircleColor = Color3.fromRGB(255, 0, 0)
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

-- Create FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Color = Aimbot.Settings.FOVCircleColor
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

local function getClosestTarget()
    refreshPlayerCache()
    local bestTarget, lowestAngle = nil, Aimbot.Settings.AimFOV
    local camPos = Camera.CFrame.Position
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local ray = Camera:ScreenPointToRay(screenCenter.X, screenCenter.Y)
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
                    if angle <= lowestAngle then
                        local losOK = not Aimbot.Settings.UseLineOfSight or checkLineOfSight(otherPlayer.Character)
                        if losOK then
                            bestTarget = targetPart
                            lowestAngle = angle
                        end
                    end
                end
            end
        end
    end
    return bestTarget
end

local function updateFOVCircle()
    fovCircle.Visible = Aimbot.Settings.ShowFOVCircle
    if not Aimbot.Settings.ShowFOVCircle then return end

    fovCircle.Color = Aimbot.Settings.FOVCircleColor
    local camFOV = Camera.FieldOfView
    local screenHeight = Camera.ViewportSize.Y
    local scale = math.tan(math.rad(Aimbot.Settings.AimFOV / 2)) / math.tan(math.rad(camFOV / 2))
    fovCircle.Radius = (screenHeight / 2) * scale
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

function Aimbot.Start()
    if Aimbot._conn then Aimbot._conn:Disconnect() end

    Aimbot._conn = RunService.RenderStepped:Connect(function()
        if not player.Character or not Camera then return end

        updateFOVCircle()
        if not Aimbot.Settings.Enabled then return end

        local targetPart = getClosestTarget()
        if targetPart then
            local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            local ray = Camera:ScreenPointToRay(screenCenter.X, screenCenter.Y)
            local aimOrigin = ray.Origin
            local assistDir = (targetPart.Position - aimOrigin).Unit
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