if getgenv().Aimbot then
    return getgenv().Aimbot
end

local Aimbot = {}
getgenv().Aimbot = Aimbot

local rawSettings = {
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

local fovCircle
local function updateFOVCircle()
    if not fovCircle then return end
    fovCircle.Visible = rawSettings.ShowFOVCircle
    if not rawSettings.ShowFOVCircle then return end
    fovCircle.Color = rawSettings.FOVCircleColor
    local camFOV = workspace.CurrentCamera.FieldOfView
    local screenHeight = workspace.CurrentCamera.ViewportSize.Y
    local aimFOV = math.clamp(rawSettings.AimFOV, 1, 180)
    local scale = math.tan(math.rad(aimFOV / 2)) / math.tan(math.rad(camFOV / 2))
    fovCircle.Radius = (screenHeight / 2) * scale
    fovCircle.Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)
end

Aimbot.Settings = setmetatable({}, {
    __index = rawSettings,
    __newindex = function(_, key, value)
        rawSettings[key] = value
        if key == "ShowFOVCircle" or key == "FOVCircleColor" or key == "AimFOV" then
            updateFOVCircle()
        end
    end
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local player = Players.LocalPlayer

if getgenv().AimbotFOVCircle then
    getgenv().AimbotFOVCircle:Remove()
    getgenv().AimbotFOVCircle = nil
end

fovCircle = Drawing.new("Circle")
fovCircle.Color = rawSettings.FOVCircleColor
fovCircle.Thickness = 2
fovCircle.Filled = false
fovCircle.Transparency = 0.4
fovCircle.Visible = rawSettings.ShowFOVCircle
getgenv().AimbotFOVCircle = fovCircle

local cachedPlayers, lastPlayerCache = {}, 0
local function refreshPlayerCache()
    if tick() - lastPlayerCache > 0.25 then
        cachedPlayers = Players:GetPlayers()
        lastPlayerCache = tick()
    end
end

local function checkLineOfSight(char)
    for _, partName in ipairs(rawSettings.LOSParts) do
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
    local bestTarget, lowestAngle = nil, rawSettings.AimFOV
    local camPos = Camera.CFrame.Position
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local ray = Camera:ScreenPointToRay(screenCenter.X, screenCenter.Y)
    local aimOrigin = ray.Origin
    local aimDirection = ray.Direction.Unit

    for _, otherPlayer in ipairs(cachedPlayers) do
        if otherPlayer ~= player and otherPlayer.Character then
            local targetPart = otherPlayer.Character:FindFirstChild(rawSettings.TargetPart)
            local humanoid = otherPlayer.Character:FindFirstChildOfClass("Humanoid")
            if targetPart and (not rawSettings.HealthCheck or (humanoid and humanoid.Health > 0)) then
                if not rawSettings.TeamCheck or otherPlayer.Team ~= player.Team then
                    local toTarget = (targetPart.Position - aimOrigin).Unit
                    local angle = math.deg(math.acos(math.clamp(aimDirection:Dot(toTarget), -1, 1)))
                    if angle <= lowestAngle then
                        local losOK = not rawSettings.UseLineOfSight or checkLineOfSight(otherPlayer.Character)
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

function Aimbot.Start()
    if Aimbot._conn then Aimbot._conn:Disconnect() end

    Aimbot._conn = RunService.RenderStepped:Connect(function()
        if not player.Character or not Camera then return end
        updateFOVCircle()
        if not rawSettings.Enabled then return end

        local targetPart = getClosestTarget()
        if targetPart then
            local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            local ray = Camera:ScreenPointToRay(screenCenter.X, screenCenter.Y)
            local aimOrigin = ray.Origin
            local assistDir = (targetPart.Position - aimOrigin).Unit
            local currentCFrame = Camera.CFrame
            local targetCFrame = CFrame.new(currentCFrame.Position, currentCFrame.Position + assistDir)
            local smoothing = math.clamp(rawSettings.AimSmoothing, 0, 1)
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
